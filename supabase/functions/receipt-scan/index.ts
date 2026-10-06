// SmartBudget — receipt-scan (Supabase Edge Function, Deno).
//
// Receives a receipt image from a signed-in user and asks Gemini Flash — with
// DGOTIX's server key (DGOTIX is the only AI provider; users never bring their
// own key) — to extract a strict, schema-constrained JSON object. Every scan is
// metered against the plan's cloud-OCR quota. The key never reaches the
// frontend and no value is ever invented — an unreadable image returns
// { ok:false, reason }.
//
//   POST { imageBase64, mimeType } ->            (v1, older app versions)
//     { ok:true, merchant_name, date, total_amount, currency, category, confidence }
//     | { ok:false, reason: "unreadable" | "no_total" }
//     | { error: "ocr_unavailable" | "quota_exceeded" | "provider_error" | ... }
//
//   POST { imageBase64, mimeType, v: 2 } ->       (invoice reader)
//   POST { images: [b64, b64, b64], mimeType, v: 2 } -> the same, for a very
//     long receipt cut into overlapping strips: read in parallel, merged
//     (header from the first, totals from the last), counted as one scan.
//     { ok:true, v:2, data:{ r, inv, dt, cur, sym, sup, cus, cat,
//                            it:[{ n, q, u, t, c }], sub, dis, tax, tot, paid, due },
//       ms:{ model, parts } }
//     | { ok:false, reason } | { error }
//   v2 reads only the header, the item lines and the totals, and copies every
//   amount exactly as printed: the app decides the number format and checks
//   the arithmetic itself (it never trusts computed figures from the model).
//   Short keys keep the output, and so the wait, small.
//
// Deploy:  supabase functions deploy receipt-scan
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { mergeReadings, type Reading } from "../_shared/invoice_merge.ts";
import { HttpError, requireAccount, serviceClient } from "../_shared/auth.ts";
import { readJsonBody } from "../_shared/body.ts";
import { rateLimited, releaseUsage, reserveUsage } from "../_shared/usage.ts";
import {
  type Allowance,
  allowanceFor,
  DAILY_LIMIT,
  effectivePlan,
  normalizePlan,
  OCR_QUOTA,
  type Plan,
  trustOf,
} from "../_shared/quota.ts";

// `gemini-flash-latest` is a stable alias that always tracks the newest Flash,
// so it never 404s the way a pinned retired id (e.g. gemini-2.0-flash) does.
const MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-flash-latest";

// Size limits, well above a receipt photo from the app (at most 1280 px
// across, JPEG): one image, or three strips of a long receipt. Only image
// types are read, so nothing costlier (video, documents) can be sent.
const MAX_BODY_BYTES = 12 * 1024 * 1024;
const MAX_IMAGE_B64_CHARS = 6 * 1024 * 1024;
const IMAGE_TYPES = new Set<string>([
  "image/jpeg", "image/png", "image/webp", "image/heic", "image/heif",
]);

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

// ---- v2: invoice reader ----

const CATEGORIES_V2 = [
  ...CATEGORIES.slice(0, -1),
  "الملابس",
  "الأثاث والمنزل",
  "الصيانة والإصلاح",
  "الاتصالات والإنترنت",
  "أخرى",
];

const S = { type: "STRING" };
const SCHEMA_V2 = {
  type: "OBJECT",
  properties: {
    r: { type: "BOOLEAN" },
    inv: S,
    dt: S,
    cur: S,
    sym: S,
    sup: S,
    cus: S,
    cat: { type: "STRING", enum: CATEGORIES_V2 },
    it: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: { n: S, q: S, u: S, t: S, c: { type: "NUMBER" } },
        required: ["n", "q", "u", "t", "c"],
      },
    },
    sub: S,
    dis: S,
    tax: S,
    tot: S,
    paid: S,
    due: S,
  },
  required: [
    "r", "inv", "dt", "cur", "sym", "sup", "cus", "cat", "it",
    "sub", "dis", "tax", "tot", "paid", "due",
  ],
};

const PROMPT_V2 = [
  "Read this purchase invoice or receipt for a budgeting app. Read ONLY the",
  "header, the purchased item lines and the totals. Ignore everything else:",
  "logos, store addresses, phone numbers, websites, social media, cashier or",
  "employee names, terminal, authorization and transaction numbers, card",
  "numbers, QR codes, barcodes, legal text, ads, loyalty and thank-you",
  "messages. The receipt may be in Arabic, French, English or a mix.",
  "Rules:",
  "- Copy every amount EXACTLY as printed: digits, separators and minus sign",
  "  only, no currency sign (e.g. '1 250,50', '12.99', '-3,12'). Never",
  "  convert, round or compute an amount. A value that is not printed is ''.",
  "- it: one entry per purchased product line, top to bottom. n = product",
  "  name as printed; a product printed in several languages on consecutive",
  "  lines is ONE item (use its first name). q = quantity or weight as",
  "  printed ('' if not printed, never assume 1). u = unit price. t = line",
  "  amount. Find the columns from their headers in any language (Qty, Qté,",
  "  Quantité, الكمية; Unit price, P.U, Prix unitaire, سعر الوحدة; Total,",
  "  Montant, Amount, المجموع); column order varies. A discount printed under",
  "  an item is its own entry with its negative amount in t. c = how clearly",
  "  the line was legible, 0..1.",
  "- sub = subtotal (Subtotal, Sous-total, Total HT, المجموع الفرعي). dis =",
  "  total discount (Discount, Remise, الخصم). tax = tax amount (VAT, TVA,",
  "  الضريبة). tot = grand total to pay (Total, Total TTC, Net à payer, Grand",
  "  total, الإجمالي). paid = amount paid or tendered. due = amount due or",
  "  balance left to pay.",
  "- inv = invoice or receipt number. dt = date as YYYY-MM-DD (dd/mm/yyyy on",
  "  French and Arabic receipts); '' if absent.",
  "- sym = the currency sign or word exactly as printed (DA, د.ج, €, $, DH,",
  "  SAR...). cur = its ISO 4217 code only when certain, else ''.",
  "- sup = store or supplier name. cus = customer name if printed.",
  "- cat = the best fit from the allowed list.",
  "- r = false only when the image is not an invoice or cannot be read.",
  "- Never guess or invent a value: when unsure, use ''.",
].join(" ");

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  // The scan counted up front, given back unless a reading comes of it.
  const usage: ScanUsage = { reserved: false, counted: false };
  let giveBack: (() => Promise<void>) | null = null;
  try {
    const account = await requireAccount(req);
    const userId = account.id;
    const db = serviceClient();
    // Before reading a body of up to 12 MB.
    if (await rateLimited(db, userId, "ocr")) {
      return jsonResponse({ error: "rate_limited" }, 429, cors);
    }
    const body = await readJsonBody(req, MAX_BODY_BYTES);
    const imageBase64 = String(body?.imageBase64 ?? "");
    const requestedType = String(body?.mimeType ?? "").toLowerCase();
    const mimeType = IMAGE_TYPES.has(requestedType) ? requestedType : "image/jpeg";
    // A very long receipt comes as strips (v2), read in parallel.
    const images: string[] = Array.isArray(body?.images)
      ? (body.images as unknown[]).map((v) => String(v ?? "")).filter((v) => v)
        .slice(0, 3)
      : [];
    if (!imageBase64 && images.length === 0) {
      return jsonResponse({ error: "no_image" }, 400, cors);
    }
    if (
      imageBase64.length > MAX_IMAGE_B64_CHARS ||
      images.some((b64) => b64.length > MAX_IMAGE_B64_CHARS)
    ) {
      return jsonResponse({ error: "too_large" }, 413, cors);
    }

    // DGOTIX's server key only. Without it the cloud scanner is simply not
    // available yet (the app falls back to on-device OCR where it can).
    const apiKey = (Deno.env.get("GEMINI_API_KEY") ?? "").trim();
    if (!apiKey) return jsonResponse({ error: "ocr_unavailable" }, 503, cors);

    // Every cloud scan is metered per plan (docs/PRICING.md §3).
    const month = monthKey();
    const { plan, paidPlan } = await resolvePlan(db, userId);
    // A new or unconfirmed account doesn't get the plan's full allowance
    // (beta gives everyone PRO): see supabase/abuse_limits.sql.
    const trust = trustOf(paidPlan, account);
    const allow = allowanceFor(OCR_QUOTA[plan], "ocr", trust);
    if (await ocrQuotaExceeded(db, userId, month, allow)) {
      return jsonResponse({ error: "quota_exceeded" }, 429, cors);
    }
    // Count the scan now, atomically, so parallel scans can't all pass the
    // check above (null: database not updated yet, counted on success).
    const reservation = await reserveUsage(db, userId, "ocr", month, {
      allow,
      daily: DAILY_LIMIT[trust].ocr,
      trust,
    });
    if (reservation === "quota") {
      return jsonResponse({ error: "quota_exceeded" }, 429, cors);
    }
    if (reservation === "daily") {
      return jsonResponse({ error: "quota_exceeded", scope: "daily" }, 429, cors);
    }
    if (
      reservation === "global" || reservation === "pool" ||
      reservation === "error"
    ) {
      // The app reads the receipt on the device instead.
      return jsonResponse({ error: "ocr_unavailable" }, 503, cors);
    }
    usage.reserved = reservation === "ok";
    giveBack = () => releaseUsage(db, userId, "ocr", month, trust);

    if (Number(body?.v) === 2) {
      return await scanV2(
        db,
        userId,
        month,
        apiKey,
        images.length > 0 ? images : [imageBase64],
        mimeType,
        cors,
        usage,
      );
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
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
      {
        method: "POST",
        // The key goes in a header, never the URL (URLs end up in logs).
        headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
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
    await countScan(db, userId, month, usage);

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
  } finally {
    if (usage.reserved && !usage.counted) await giveBack?.();
  }
});

/** Whether this request's scan was counted up front, and whether it counts. */
interface ScanUsage {
  reserved: boolean;
  counted: boolean;
}

/** A reading was served: it counts (already, when reserved up front). */
async function countScan(
  db: ReturnType<typeof serviceClient>,
  userId: string,
  month: string,
  usage: ScanUsage,
): Promise<void> {
  usage.counted = true;
  if (!usage.reserved) await bumpOcr(db, userId, month);
}

/** v2: one structured-extraction call per image (several, in parallel, for
 * the strips of a very long receipt); the app parses and checks the result. */
async function scanV2(
  db: ReturnType<typeof serviceClient>,
  userId: string,
  month: string,
  apiKey: string,
  images: string[],
  mimeType: string,
  cors: HeadersInit,
  usage: ScanUsage,
): Promise<Response> {
  const started = Date.now();
  const n = images.length;
  const results = await Promise.all(
    images.map((img, i) =>
      readOne(
        apiKey,
        img,
        mimeType,
        n > 1
          ? ` This image is part ${i + 1} of ${n} of ONE long receipt, cut top ` +
            "to bottom with a small overlap. Read the item lines it shows; " +
            "read header fields only if they appear in it, and totals only " +
            "if they appear in it (else '')."
          : "",
      )
    ),
  );
  const failed = results.find((r) => "error" in r);
  if (failed && "error" in failed) {
    return jsonResponse({ error: failed.error }, failed.status, cors);
  }
  const parts = results.map((r) => (r as { data: Reading }).data);
  const d: Reading = n > 1 ? mergeReadings(parts) : parts[0];

  if (d.r === false) {
    return jsonResponse({ ok: false, reason: "unreadable" }, 200, cors);
  }
  const items = Array.isArray(d.it) ? d.it as Record<string, unknown>[] : [];
  const hasAmount = [d.tot, d.sub, d.due].some((v) => toStr(v) !== "") ||
    items.some((i) => toStr(i?.t) !== "");
  if (!hasAmount) {
    return jsonResponse({ ok: false, reason: "no_total" }, 200, cors);
  }

  // One receipt, one scan, however many strips it took.
  await countScan(db, userId, month, usage);

  // Card numbers never leave the server, even if the model copied one.
  const data = {
    r: true,
    inv: toStr(d.inv),
    dt: normalizeDate(toStr(d.dt)),
    cur: toStr(d.cur).toUpperCase().slice(0, 3),
    sym: toStr(d.sym).slice(0, 8),
    sup: maskCards(toStr(d.sup)),
    cus: maskCards(toStr(d.cus)),
    cat: CATEGORIES_V2.includes(toStr(d.cat)) ? toStr(d.cat) : "أخرى",
    it: items.slice(0, 300).map((i) => ({
      n: maskCards(toStr(i?.n)),
      q: toStr(i?.q),
      u: toStr(i?.u),
      t: toStr(i?.t),
      c: clamp01(toNumber(i?.c) ?? 0.9),
    })),
    sub: toStr(d.sub),
    dis: toStr(d.dis),
    tax: toStr(d.tax),
    tot: toStr(d.tot),
    paid: toStr(d.paid),
    due: toStr(d.due),
  };
  return jsonResponse(
    { ok: true, v: 2, data, ms: { model: Date.now() - started, parts: n } },
    200,
    cors,
  );
}

/** One Gemini reading of one image: the parsed JSON, or an error to return. */
async function readOne(
  apiKey: string,
  imageBase64: string,
  mimeType: string,
  partNote: string,
): Promise<{ data: Reading } | { error: string; status: number }> {
  const call = (noThinking: boolean) =>
    fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
      {
        method: "POST",
        // The key goes in a header, never the URL (URLs end up in logs).
        headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
        body: JSON.stringify({
          contents: [{
            parts: [
              { text: PROMPT_V2 + partNote },
              { inline_data: { mime_type: mimeType, data: imageBase64 } },
            ],
          }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: SCHEMA_V2,
            temperature: 0,
            maxOutputTokens: 8192,
            // Reading a receipt needs no reasoning: skipping the model's
            // "thinking" step is the biggest saving in waiting time.
            ...(noThinking ? { thinkingConfig: { thinkingBudget: 0 } } : {}),
          },
        }),
      },
    );

  let res = await call(true);
  // A model that can't turn thinking off rejects the setting: ask again
  // without it rather than failing the scan.
  if (res.status === 400) {
    const detail = await res.text();
    if (/thinking/i.test(detail)) res = await call(false);
    else return { error: "ocr_unavailable", status: 503 };
  }
  if (res.status === 401 || res.status === 403 || res.status === 400) {
    return { error: "ocr_unavailable", status: 503 };
  }
  if (res.status === 429) return { error: "rate_limited", status: 429 };
  if (!res.ok) return { error: "provider_error", status: 502 };

  const out = await res.json();
  const text: string | undefined =
    out?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) return { error: "empty_response", status: 502 };
  try {
    return { data: JSON.parse(text) as Reading };
  } catch {
    return { error: "bad_json", status: 502 };
  }
}

/** Hides anything shaped like a payment card number (Luhn-valid). */
function maskCards(s: string): string {
  return s.replace(/\b\d(?:[ -]?\d){12,18}\b/g, (m) => {
    const digits = m.replace(/[ -]/g, "");
    let sum = 0;
    let dbl = false;
    for (let i = digits.length - 1; i >= 0; i--) {
      let n = digits.charCodeAt(i) - 48;
      if (dbl) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      dbl = !dbl;
    }
    return sum % 10 === 0 ? `•••• ${digits.slice(-4)}` : m;
  });
}

function monthKey(): string {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

/** The plan in force, and the plan actually paid for (Free if none). */
async function resolvePlan(
  db: ReturnType<typeof serviceClient>,
  userId: string,
): Promise<{ plan: Plan; paidPlan: Plan }> {
  const { data: ent } = await db.from("ai_entitlements")
    .select("plan, trial_plan, trial_expires_at")
    .eq("user_id", userId).maybeSingle();
  const paidPlan = normalizePlan(ent?.plan);
  return {
    paidPlan,
    plan: effectivePlan(
      paidPlan,
      ent?.trial_plan ? normalizePlan(ent.trial_plan) : null,
      (ent?.trial_expires_at as string | null) ?? null,
    ),
  };
}

/** True when the server-served cloud OCR allowance is spent. */
async function ocrQuotaExceeded(
  db: ReturnType<typeof serviceClient>,
  userId: string,
  month: string,
  allow: Allowance,
): Promise<boolean> {
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
