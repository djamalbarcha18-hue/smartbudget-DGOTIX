// SmartBudget — receipt-scan (Supabase Edge Function, Deno).
//
// Receives a receipt image from a signed-in user, loads THAT user's own Gemini
// key (BYOK, decrypted server-side), and asks Gemini Flash to extract a strict,
// schema-constrained JSON object. The API key never reaches the frontend and no
// value is ever invented — an unreadable image returns { ok:false, reason }.
//
//   POST { imageBase64, mimeType } ->
//     { ok:true, merchant_name, date, total_amount, currency, category, confidence }
//     | { ok:false, reason: "unreadable" | "no_total" }
//     | { error: "no_key" | "invalid_key" | "provider_error" | ... }
//
// Deploy:  supabase functions deploy receipt-scan
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId } from "../_shared/auth.ts";
import { loadGeminiKey } from "../_shared/keys.ts";

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

    const apiKey = await loadGeminiKey(userId);
    if (!apiKey) return jsonResponse({ error: "no_key" }, 400, cors);

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

    // A bad or unauthorized key surfaces as 400/403 from Google.
    if (res.status === 400 || res.status === 401 || res.status === 403) {
      return jsonResponse({ error: "invalid_key" }, 400, cors);
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
