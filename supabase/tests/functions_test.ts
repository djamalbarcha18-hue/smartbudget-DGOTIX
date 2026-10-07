// Security scenarios for the Edge Functions: payment webhooks, checkout and
// usage limits, through the real handlers (harness.ts: stubbed providers,
// in-memory database). The subscription lifecycle itself, on the real SQL, is
// in subscription_lifecycle_test.ts.
//   deno run -A --import-map supabase/tests/import_map.json supabase/tests/functions_test.ts
// Exits non-zero when a scenario fails.
// deno-lint-ignore-file no-explicit-any
import { check, db, finish, load, model, paddle, paddleSub, paypal, paypalSub, PRICES, sign } from "./harness.ts";

const handlers = await load("paddle-webhook", "paypal-webhook", "create-checkout", "receipt-scan", "ai-gateway");
db.tables.billing_prices = PRICES;
const U1 = "11111111-1111-4111-8111-111111111111";
const calls = () => db.calls.length;
const last = () => db.calls[db.calls.length - 1] ?? {};

// ---- Payment webhooks: what reaches the subscription ledger ----
let r = await paddle(paddleSub("e1", "subscription.activated", U1, "sub_1", "pri_pro", "active", "2026-10-01T10:00:00Z"));
check("Paddle: a paid subscription is applied with our price's plan", r.status === 200 && last().p_plan === "pro" && last().p_status === "active" && last().p_user === U1 && last().p_subscription_id === "sub_1", JSON.stringify(last()));
let n = calls();
r = await paddle(paddleSub("e1", "subscription.activated", U1, "sub_1", "pri_pro", "active", "2026-10-01T10:00:00Z"));
check("Paddle: the same event twice is applied once", r.body.duplicate === true && calls() === n, JSON.stringify(r));
r = await paddle(paddleSub("e2", "subscription.activated", U1, "sub_2", "pri_cheap_other", "active", "2026-10-01T10:00:00Z", { custom_data: { user_id: U1, plan: "pro" } }));
check("Paddle: unknown price + custom plan 'pro' grants nothing", r.body.ignored === "unknown_price" && calls() === n, JSON.stringify(r));
db.failRpc = "apply_subscription_event";
r = await paddle(paddleSub("e6", "subscription.activated", U1, "sub_4", "pri_pro", "active", "2026-10-01T10:00:00Z"));
const marked = (db.tables.billing_events ?? []).some((e: any) => e.event_id === "e6");
check("Paddle: a failed write answers 500 and forgets the event", r.status === 500 && !marked, JSON.stringify(r) + marked);
db.failRpc = "";
r = await paddle(paddleSub("e6", "subscription.activated", U1, "sub_4", "pri_pro", "active", "2026-10-01T10:00:00Z"));
check("Paddle: the retry is then applied", r.status === 200 && last().p_subscription_id === "sub_4", JSON.stringify(r));
n = calls();
r = await paddle(paddleSub("e7", "subscription.activated", U1, "sub_5", "pri_pro", "active", "2026-10-01T10:00:00Z"), "ts=1;h1=00");
check("Paddle: a forged signature is refused", r.status === 401 && calls() === n, JSON.stringify(r));
const stale = paddleSub("e8", "subscription.activated", U1, "sub_5", "pri_pro", "active", "2026-10-01T10:00:00Z");
r = await paddle(stale, await sign(JSON.stringify(stale), Math.floor(Date.now() / 1000) - 3600));
check("Paddle: a correctly signed but hour-old delivery is refused", r.status === 401 && calls() === n, JSON.stringify(r));
r = await paddle({ event_id: "e9", event_type: "adjustment.updated", occurred_at: "2026-10-02T10:00:00Z", data: { action: "refund", type: "partial", status: "approved", subscription_id: "sub_1" } });
check("Paddle: a partial refund changes nothing", r.body.ignored === "partial_refund" && calls() === n, JSON.stringify(r));
r = await paddle({ event_id: "e10", event_type: "adjustment.created", occurred_at: "2026-10-02T10:00:00Z", data: { action: "refund", type: "full", status: "pending_approval", subscription_id: "sub_1" } });
check("Paddle: a refund awaiting approval changes nothing", r.body.ignored === "not_approved" && calls() === n, JSON.stringify(r));

r = await paypal(paypalSub("p1", "BILLING.SUBSCRIPTION.ACTIVATED", U1, "I-1", "P-PRO", "ACTIVE", "2026-10-01T10:00:00Z"));
check("PayPal: a paid subscription is applied with our plan", last().p_provider === "paypal" && last().p_plan === "pro" && last().p_status === "active", JSON.stringify(last()));
n = calls();
r = await paypal(paypalSub("p2", "BILLING.SUBSCRIPTION.ACTIVATED", U1, "I-1", "P-UNKNOWN", "ACTIVE", "2026-10-02T10:00:00Z"));
check("PayPal: an unknown plan neither grants nor removes", r.body.ignored === "unknown_plan" && calls() === n, JSON.stringify(r));

// ---- Checkout: one subscription at a time ----
const checkout = async (u: string) => {
  const res = await handlers["create-checkout"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-" + u }, body: JSON.stringify({ plan: "pro", period: "monthly" }) }));
  return { status: res.status, body: await res.json() };
};
db.tables.billing_subscriptions = [
  { user_id: "c1", status: "active", cancel_at_period_end: false },
  { user_id: "c2", status: "active", cancel_at_period_end: true },
  { user_id: "c3", status: "past_due", cancel_at_period_end: false },
  { user_id: "c4", status: "canceled", cancel_at_period_end: false },
];
r = await checkout("c1");
check("Checkout: refused while a subscription is running", r.status === 409 && r.body.error === "already_subscribed", JSON.stringify(r));
r = await checkout("c3");
check("Checkout: refused while a payment has failed (fix it from Manage)", r.status === 409, JSON.stringify(r));
r = await checkout("c2");
check("Checkout: allowed once the current subscription is set to end", r.status === 200 && !!r.body.url, JSON.stringify(r));
r = await checkout("c4");
check("Checkout: allowed after a cancelled subscription", r.status === 200 && !!r.body.url, JSON.stringify(r));
r = await checkout("c5");
check("Checkout: allowed with no subscription", r.status === 200 && !!r.body.url, JSON.stringify(r));

// ---- Usage limits (BETA off: FREE = 3 lifetime scans, 5 lifetime AI answers) ----
const scan = () => handlers["receipt-scan"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-u7" }, body: JSON.stringify({ imageBase64: "AAAA", mimeType: "image/jpeg", v: 2 }) }));
model.reply = JSON.stringify({ r: true, inv: "", dt: "2026-10-01", cur: "USD", sym: "$", sup: "S", cus: "", cat: "x", it: [], sub: "", dis: "", tax: "", tot: "9.50", paid: "", due: "" });
model.calls = 0;
const codes = await Promise.all(Array.from({ length: 10 }, () => scan().then((x) => x.status)));
const used = db.tables.ocr_usage_lifetime?.find((x: any) => x.user_id === "u7")?.scans;
check("OCR: 10 parallel scans on a 3-scan allowance: 3 served", codes.filter((c) => c === 200).length === 3 && model.calls === 3 && used === 3, codes.join(",") + " calls=" + model.calls + " used=" + used);
model.reply = JSON.stringify({ r: false });
const before = db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans;
db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans = 1;
db.tables.ocr_usage_monthly.forEach((x: any) => { if (x.user_id === "u7") x.scans = 1; });
const unreadable = await scan();
check("OCR: an unreadable photo gives its scan back", (await unreadable.json()).reason === "unreadable" && db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans === 1, String(before));

const ask = (u: string) => handlers["ai-gateway"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-" + u }, body: JSON.stringify({ prompt: "hi" }) }));
model.calls = 0;
const ai = await Promise.all(Array.from({ length: 12 }, () => ask("u8").then((x) => x.status)));
check("AI: 12 parallel questions on a 5-answer allowance: 5 answered", ai.filter((c) => c === 200).length === 5 && model.calls === 5, ai.join(",") + " calls=" + model.calls);

// A busy model (503) falls back to the next one; a retired model (404) no
// longer ends the fallback.
model.fail = { "gemini-flash-lite-latest": 503 };
model.asked = [];
let fb = await ask("u9");
check("AI: a busy model falls back to the other one", fb.status === 200 && model.asked.join(",") === "gemini-flash-lite-latest,gemini-flash-latest", fb.status + " " + model.asked.join(","));
model.fail = { "gemini-flash-lite-latest": 404 };
model.asked = [];
fb = await ask("u10");
check("AI: a retired model (404) falls back too", fb.status === 200 && model.asked.length === 2, fb.status + " " + model.asked.join(","));
model.fail = {};

finish();
