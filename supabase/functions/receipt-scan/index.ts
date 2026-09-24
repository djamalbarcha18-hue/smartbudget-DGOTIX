// SmartBudget — receipt-scan (Supabase Edge Function, Deno).
//
// Receives a receipt image from a signed-in user and asks Gemini Flash — with
// DGOTIX's server key (DGOTIX is the only AI provider; users never bring their
// own key) — to extract a strict, schema-constrained JSON object. Every scan is
// metered against the plan's cloud-OCR quota. The key never reaches the
// frontend and no value is ever invented — an unreadable image returns
// { ok:false, reason }.
//
//   POST { imageBase64, mimeType } ->
//     { ok:true, merchant_name, date, total_amount, currency, category, confidence }
//     | { ok:false, reason: "unreadable" | "no_total" }
//     | { error: "ocr_unavailable" | "quota_exceeded" | "provider_error" | ... }
//
// Deploy:  supabase functions deploy receipt-scan
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import {
  effectivePlan,
  normalizePlan,
  OCR_QUOTA,
  type Plan,
} from "../_shared/quota.ts";

// `gemini-flash-latest` is a stable alias that always tracks the newest Flash,
// so it never 404s the way a pinned retired id (e.g. gemini-2.0-flash) does.
const MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-flash-latest";

// Categories mirror the app's expense taxonomy (Arabic canonical labels).
const CATEGORIES = [
  "الطعام",
  "المطاعم",
  "النقل",
  "الوقود",
  "الفواتير",
  "التسوق",
  "الصحة",
  "الترفيه",
  "السفر",
  "التعليم",
  "أخرى",
];

const RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    readable: { type: "BOOLEAN" },
    merchant_name: { type: "STRING" },
    date: { type: "STRING" },
    total_amount: { type: "NUMBER" },
    currency: { type: "STRING" },
    category: { type: "STRING", enum: CATEGORIES },
    confidence: { type: "NUMBER" },
  },
  required: [
    "readable",
    "merchant_name",
    "date",
    "total_amount",
    "currency",
    "category",
    "confidence",
  ],
};

const PROMPT = [
  "You extract structured data from a photo of a purchase receipt for a",
  "personal budgeting app. Rules:",
  "- date: ISO format YYYY-MM-DD. If the year is missing, infer it from the",
  "  receipt; if the whole date is missing, use an empty string.",
  "- total_amount: the final grand total actually paid, as a plain number with",
  "  a dot decimal separator and NO currency symbol or thousands separators.",
  "- currency: the ISO 4217 code (USD, EUR, SAR, AED, DZD, MAD, EGP, …). Infer",
  "  it from currency symbols or the receipt language when not written.",
  "- category: choose the single best fit strictly from the allowed enum.",
  "- If the image is blurry, not a receipt, or you cannot read the total, set",
  "  readable=false and return best-effort/empty values.",
  "- confidence: 0..1, your confidence in total_amount.",
  "Return ONLY JSON that matches the provided schema.",
].join(" ");

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    const body = await req.json().catch(() => ({}));
    const imageBase64 = String(body?.imageBase64 ?? "");
    const mimeType = String(body?.mimeType ?? "image/jpeg");
    if (!imageBase64) return jsonResponse({ error: "no_image" }, 400, cors);

    // DGOTIX's server key only. Without it the cloud scanner is simply not
    // available yet (the app falls back to on-device OCR where it can).
    const apiKey = (Deno.env.get("GEMINI_API_KEY") ?? "").trim();
    if (!apiKey) return jsonResponse({ error: "ocr_unavailable" }, 503, cors);

    // Every cloud scan is metered per plan (docs/PRICING.md §3).
    const db = serviceClient();
    const month = monthKey();
    if (await ocrQuotaExceeded(db, userId, month)) {
      return jsonResponse({ error: "quota_exceeded" }, 429, cors);
    }

    const geminiBody = {
      contents: [
        {
          parts: [
            { text: PROMPT },
            { inline_data: { mime_type: mimeType, data: imageBase64 } },
          ],
        },
      ],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: RESPONSE_SCHEMA,
        temperature: 0,
      },
    };

    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(geminiBody),
      },
    );

    // A bad or unauthorized key is OUR configuration problem, never the
    // user's: report the service as unavailable.
    if (res.status === 400 || res.status === 401 || res.status === 403) {
      return jsonResponse({ error: "ocr_unavailable" }, 503, cors);
    }
    if (res.status === 429) {
      return jsonResponse({ error: "rate_limited" }, 429, cors);
    }
    if (!res.ok) return jsonResponse({ error: "provider_error" }, 502, cors);

    const data = await res.json();
    const text: string | undefined =
      data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return jsonResponse({ error: "empty_response" }, 502, cors);

    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(text);
    } catch {
      return jsonResponse({ error: "bad_json" }, 502, cors);
    }

    if (parsed.readable === false) {
      return jsonResponse({ ok: false, reason: "unreadable" }, 200, cors);
    }

    const total = toNumber(parsed.total_amount);
    if (total === null || total <= 0) {
      return jsonResponse({ ok: false, reason: "no_total" }, 200, cors);
    }

    // Count only a successful extraction, and only when we served it.
    await bumpOcr(db, userId, month);

    return jsonResponse(
      {
        ok: true,
        merchant_name: toStr(parsed.merchant_name),
        date: normalizeDate(toStr(parsed.date)),
        total_amount: total,
        currency: toStr(parsed.currency).toUpperCase().slice(0, 3),
        category: CATEGORIES.includes(toStr(parsed.category))
          ? toStr(parsed.category)
          : "أخرى",
        confidence: clamp01(toNumber(parsed.confidence) ?? 0),
      },
      200,
      cors,
    );
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, cors);
  }
});

function monthKey(): string {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

async function resolvePlan(
  db: ReturnType<typeof serviceClient>,
  userId: string,
): Promise<Plan> {
  const { data: ent } = await db.from("ai_entitlements")
    .select("plan, trial_plan, trial_expires_at")
    .eq("user_id", userId).maybeSingle();
  return effectivePlan(
    normalizePlan(ent?.plan),
    ent?.trial_plan ? normalizePlan(ent.trial_plan) : null,
    (ent?.trial_expires_at as string | null) ?? null,
  );
}

/** True when the server-served cloud OCR allowance for the plan is spent. */
async function ocrQuotaExceeded(
  db: ReturnType<typeof serviceClient>,
  userId: string,
  month: string,
): Promise<boolean> {
  const allow = OCR_QUOTA[await resolvePlan(db, userId)];
  let used: number;
  if (allow.window === "lifetime") {
    const { data } = await db.from("ocr_usage_lifetime")
      .select("scans").eq("user_id", userId).maybeSingle();
    used = data?.scans ?? 0;
  } else {
    const { data } = await db.from("ocr_usage_monthly")
      .select("scans").eq("user_id", userId).eq("month", month).maybeSingle();
    used = data?.scans ?? 0;
  }
  return used >= allow.limit;
}

/** Increment both the monthly and lifetime cloud-OCR counters. */
async function bumpOcr(
  db: ReturnType<typeof serviceClient>,
  userId: string,
  month: string,
): Promise<void> {
  const nowIso = new Date().toISOString();
  try {
    const { data: cur } = await db.from("ocr_usage_monthly")
      .select("scans").eq("user_id", userId).eq("month", month).maybeSingle();
    await db.from("ocr_usage_monthly").upsert({
      user_id: userId,
      month,
      scans: (cur?.scans ?? 0) + 1,
      updated_at: nowIso,
    });
  } catch (_) { /* non-fatal */ }
  try {
    const { data: life } = await db.from("ocr_usage_lifetime")
      .select("scans").eq("user_id", userId).maybeSingle();
    await db.from("ocr_usage_lifetime").upsert({
      user_id: userId,
      scans: (life?.scans ?? 0) + 1,
      updated_at: nowIso,
    });
  } catch (_) { /* non-fatal */ }
}

function toStr(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function toNumber(v: unknown): number | null {
  if (typeof v === "number" && isFinite(v)) return v;
  if (typeof v === "string") {
    const n = parseFloat(v.replace(/[^0-9.\-]/g, ""));
    return isFinite(n) ? n : null;
  }
  return null;
}

function clamp01(n: number): number {
  return n < 0 ? 0 : n > 1 ? 1 : n;
}

// Accepts YYYY-MM-DD as-is; returns "" for anything else so the client falls
// back to "today" rather than a wrong date.
function normalizeDate(s: string): string {
  return /^\d{4}-\d{2}-\d{2}$/.test(s) ? s : "";
}
