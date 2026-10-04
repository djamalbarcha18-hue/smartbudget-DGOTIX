// Security scenarios for the Edge Functions: payment webhooks and usage
// limits. Each function's handler is captured instead of served, outside
// services are stubbed, and the database is the in-memory fake_supabase.ts.
//   deno run -A --import-map supabase/tests/import_map.json supabase/tests/functions_test.ts
// Exits non-zero when a scenario fails.
// deno-lint-ignore-file no-explicit-any
for (const [k, v] of Object.entries({
  BETA_ALL_ACCESS: "false", PADDLE_WEBHOOK_SECRET: "whsec_test", PAYPAL_CLIENT_ID: "c",
  PAYPAL_SECRET: "s", PAYPAL_WEBHOOK_ID: "w", PAYPAL_API_URL: "https://api-m.sandbox.paypal.com",
  GEMINI_API_KEY: "k", SUPABASE_URL: "http://x", SUPABASE_ANON_KEY: "a", SUPABASE_SERVICE_ROLE_KEY: "s",
})) Deno.env.set(k, v);
const g = globalThis as any;
g.__db = { tables: {}, failTable: "" };
const db = g.__db;
const handlers: Record<string, (r: Request) => Promise<Response>> = {};
let current = "";
(Deno as any).serve = (h: any) => { handlers[current] = h; return { finished: Promise.resolve() }; };
let modelReply = "ok"; let modelCalls = 0;
globalThis.fetch = (async (input: any, init?: any) => {
  const url = String(input instanceof Request ? input.url : input);
  if (url.includes("generativelanguage")) {
    modelCalls++;
    const h = new Headers(init?.headers);
    if (url.includes("key=") || h.get("x-goog-api-key") !== "k") throw new Error("Gemini key not sent as a header");
    await new Promise((r) => setTimeout(r, 20));
    const text = String(init?.body ?? "").includes("inline_data") ? modelReply : "ok";
    return new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text }] }, finishReason: "STOP" }], usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 2 } }));
  }
  if (url.includes("/v1/oauth2/token")) return new Response(JSON.stringify({ access_token: "t" }));
  if (url.includes("verify-webhook-signature")) return new Response(JSON.stringify({ verification_status: "SUCCESS" }));
  throw new Error("unexpected fetch " + url);
}) as typeof fetch;
for (const fn of ["paddle-webhook", "paypal-webhook", "receipt-scan", "ai-gateway"]) {
  current = fn;
  await import(new URL("../functions/" + fn + "/index.ts", import.meta.url).href);
}

const results: string[] = [];
function check(name: string, ok: boolean, detail = "") { results.push((ok ? "PASS " : "FAIL ") + name + (ok ? "" : "  -> " + detail)); }
const ent = (u: string) => db.tables.ai_entitlements?.find((r: any) => r.user_id === u)?.plan ?? "none";

async function sign(body: string, ts = Math.floor(Date.now() / 1000)) {
  const k = await crypto.subtle.importKey("raw", new TextEncoder().encode(Deno.env.get("PADDLE_WEBHOOK_SECRET")!), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(ts + ":" + body));
  return "ts=" + ts + ";h1=" + Array.from(new Uint8Array(mac)).map((b) => b.toString(16).padStart(2, "0")).join("");
}
async function paddle(evt: any, sig?: string) {
  const body = JSON.stringify(evt);
  const res = await handlers["paddle-webhook"](new Request("http://x/", { method: "POST", body, headers: { "Paddle-Signature": sig ?? await sign(body) } }));
  return { status: res.status, body: await res.json() };
}
const sub = (id: string, type: string, user: string, price: string, status: string, at: string, extra: any = {}) =>
  ({ event_id: id, event_type: type, occurred_at: at, data: { id: "sub_1", status, items: [{ price: { id: price } }], custom_data: { user_id: user, plan: "pro", ...extra } } });

db.tables.billing_prices = [
  { price_id: "pri_pro", provider: "paddle", plan: "pro", period: "monthly", active: true },
  { price_id: "pri_old", provider: "paddle", plan: "basic", period: "monthly", active: false },
  { price_id: "P-PRO", provider: "paypal", plan: "pro", period: "monthly", active: true },
];

// ---- Payments ----
let r = await paddle(sub("e1", "subscription.activated", "u1", "pri_pro", "active", "2026-10-01T10:00:00Z"));
check("Paddle: paid subscription grants the plan", r.status === 200 && ent("u1") === "pro", JSON.stringify(r) + ent("u1"));
r = await paddle(sub("e1", "subscription.activated", "u1", "pri_pro", "active", "2026-10-01T10:00:00Z"));
check("Paddle: the same event twice is applied once", r.body.duplicate === true, JSON.stringify(r));
r = await paddle(sub("e2", "subscription.activated", "u2", "pri_cheap_other", "active", "2026-10-01T10:00:00Z"));
check("Paddle: unknown price + custom plan 'pro' grants nothing", ent("u2") === "none" && r.body.ignored === "unknown_price", JSON.stringify(r) + ent("u2"));
r = await paddle(sub("e3", "subscription.canceled", "u1", "pri_pro", "canceled", "2026-10-05T10:00:00Z"));
check("Paddle: cancellation removes the plan", ent("u1") === "free", ent("u1"));
r = await paddle(sub("e4", "subscription.updated", "u1", "pri_pro", "active", "2026-10-03T10:00:00Z"));
check("Paddle: an older event delivered late doesn't undo the cancellation", ent("u1") === "free" && r.body.ignored === "older_event", JSON.stringify(r) + ent("u1"));
r = await paddle(sub("e5", "subscription.updated", "u3", "pri_old", "active", "2026-10-01T10:00:00Z"));
check("Paddle: a retired price still maps for its subscribers", ent("u3") === "basic", ent("u3"));
db.failTable = "ai_entitlements";
r = await paddle(sub("e6", "subscription.activated", "u4", "pri_pro", "active", "2026-10-01T10:00:00Z"));
const marked = (db.tables.billing_events ?? []).some((e: any) => e.event_id === "e6");
check("Paddle: a failed write answers 500 and forgets the event", r.status === 500 && !marked, JSON.stringify(r) + marked);
db.failTable = "";
r = await paddle(sub("e6", "subscription.activated", "u4", "pri_pro", "active", "2026-10-01T10:00:00Z"));
check("Paddle: the retry is then applied", r.status === 200 && ent("u4") === "pro", JSON.stringify(r) + ent("u4"));
r = await paddle(sub("e7", "subscription.activated", "u5", "pri_pro", "active", "2026-10-01T10:00:00Z"), "ts=1;h1=00");
check("Paddle: a forged signature is refused", r.status === 401 && ent("u5") === "none", JSON.stringify(r));
const stale = sub("e8", "subscription.activated", "u5", "pri_pro", "active", "2026-10-01T10:00:00Z");
r = await paddle(stale, await sign(JSON.stringify(stale), Math.floor(Date.now() / 1000) - 3600));
check("Paddle: a correctly signed but hour-old delivery is refused", r.status === 401 && ent("u5") === "none", JSON.stringify(r));

async function paypal(evt: any) {
  const res = await handlers["paypal-webhook"](new Request("http://x/", { method: "POST", body: JSON.stringify(evt) }));
  return { status: res.status, body: await res.json() };
}
r = await paypal({ id: "p1", event_type: "BILLING.SUBSCRIPTION.ACTIVATED", create_time: "2026-10-01T10:00:00Z", resource: { id: "I-1", plan_id: "P-PRO", custom_id: "u6", status: "ACTIVE" } });
check("PayPal: paid subscription grants the plan", ent("u6") === "pro", JSON.stringify(r));
r = await paypal({ id: "p2", event_type: "BILLING.SUBSCRIPTION.ACTIVATED", create_time: "2026-10-02T10:00:00Z", resource: { id: "I-1", plan_id: "P-UNKNOWN", custom_id: "u6", status: "ACTIVE" } });
check("PayPal: an unknown plan neither grants nor removes", ent("u6") === "pro" && r.body.ignored === "unknown_plan", JSON.stringify(r) + ent("u6"));

// ---- Usage limits (BETA off: FREE = 3 lifetime scans, 5 lifetime AI answers) ----
const scan = () => handlers["receipt-scan"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-u7" }, body: JSON.stringify({ imageBase64: "AAAA", mimeType: "image/jpeg", v: 2 }) }));
modelReply = JSON.stringify({ r: true, inv: "", dt: "2026-10-01", cur: "USD", sym: "$", sup: "S", cus: "", cat: "x", it: [], sub: "", dis: "", tax: "", tot: "9.50", paid: "", due: "" });
modelCalls = 0;
const codes = await Promise.all(Array.from({ length: 10 }, () => scan().then((x) => x.status)));
const used = db.tables.ocr_usage_lifetime?.find((x: any) => x.user_id === "u7")?.scans;
check("OCR: 10 parallel scans on a 3-scan allowance: 3 served", codes.filter((c) => c === 200).length === 3 && modelCalls === 3 && used === 3, codes.join(",") + " calls=" + modelCalls + " used=" + used);
modelReply = JSON.stringify({ r: false });
const before = db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans;
db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans = 1;
db.tables.ocr_usage_monthly.forEach((x: any) => { if (x.user_id === "u7") x.scans = 1; });
const unreadable = await scan();
check("OCR: an unreadable photo gives its scan back", (await unreadable.json()).reason === "unreadable" && db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans === 1, String(before));

const ask = (u: string) => handlers["ai-gateway"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-" + u }, body: JSON.stringify({ prompt: "hi" }) }));
modelCalls = 0;
const ai = await Promise.all(Array.from({ length: 12 }, () => ask("u8").then((x) => x.status)));
check("AI: 12 parallel questions on a 5-answer allowance: 5 answered", ai.filter((c) => c === 200).length === 5 && modelCalls === 5, ai.join(",") + " calls=" + modelCalls);

console.log(results.join("\n"));
const failed = results.filter((x) => x.startsWith("FAIL")).length;
console.log((results.length - failed) + " passed, " + failed + " failed");
if (failed > 0) Deno.exit(1);
