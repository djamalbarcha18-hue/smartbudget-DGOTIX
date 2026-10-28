// Security scenarios for the Edge Functions: payment webhooks, checkout and
// usage limits, through the real handlers (harness.ts: stubbed providers,
// in-memory database). The subscription lifecycle itself, on the real SQL, is
// in subscription_lifecycle_test.ts.
//   deno run -A --import-map supabase/tests/import_map.json supabase/tests/functions_test.ts
// Exits non-zero when a scenario fails.
// deno-lint-ignore-file no-explicit-any
import { check, db, finish, load, model, outbound, paypal, paypalSub, PRICES, whop, whopCheckouts, whopHeaders, whopMem, whopMemberships } from "./harness.ts";

// A short model deadline, so the "stuck model" scenario below runs quickly.
Deno.env.set("OCR_TIMEOUT_MS", "300");
const handlers = await load("whop-webhook", "paypal-webhook", "create-checkout", "receipt-scan", "ai-gateway");
db.tables.billing_prices = PRICES;
const U1 = "11111111-1111-4111-8111-111111111111";
const calls = () => db.calls.length;
const last = () => db.calls[db.calls.length - 1] ?? {};

// ---- Payment webhooks: what reaches the subscription ledger ----
let r = await whop(whopMem("membership.activated", U1, "mem_1", "plan_pro", "active"));
check("Whop: a paid membership is applied with our plan", r.status === 200 && last().p_plan === "pro" && last().p_status === "active" && last().p_user === U1 && last().p_subscription_id === "mem_1" && last().p_provider === "whop", JSON.stringify(last()));
const once = JSON.stringify(whopMem("membership.updated", U1, "mem_1", "plan_pro", "active"));
await whop(once, await whopHeaders(once, "msg_same"));
let n = calls();
r = await whop(once, await whopHeaders(once, "msg_same"));
check("Whop: the same delivery twice is applied once", r.body.duplicate === true && calls() === n, JSON.stringify(r));
r = await whop(whopMem("membership.activated", U1, "mem_2", "plan_cheap_other", "active", { metadata: { user_id: U1, plan: "pro" } }));
check("Whop: an unknown plan + metadata plan 'pro' grants nothing", r.body.ignored === "unknown_price" && calls() === n, JSON.stringify(r));
r = await whop(whopMem("membership.activated", U1, "mem_3", "plan_old", "canceling"));
check("Whop: a cancellation at period end keeps access until then", last().p_status === "active" && last().p_cancel_at_period_end === true && last().p_plan === "basic", JSON.stringify(last()));
r = await whop(whopMem("membership.deactivated", U1, "mem_3", "plan_old", "expired"));
check("Whop: an expired membership is cancelled", last().p_status === "canceled", JSON.stringify(last()));
whopMemberships["mem_1"].status = "canceled";
r = await whop({ type: "refund.created", data: { id: "rfnd_1", status: "succeeded", payment: { id: "pay_1", membership_id: "mem_1" } } });
check("Whop: a refund applies the membership as Whop now has it", last().p_subscription_id === "mem_1" && last().p_status === "canceled", JSON.stringify(last()));
n = calls();
r = await whop({ type: "refund.created", data: { id: "rfnd_2", payment: { id: "pay_2", membership_id: "mem_unknown" } } });
check("Whop: an event about a membership Whop doesn't know changes nothing", r.body.ignored === "unknown_membership" && calls() === n, JSON.stringify(r));
r = await whop({ type: "product.updated", data: { id: "prod_1" } });
check("Whop: other events are acknowledged and ignored", r.status === 200 && calls() === n, JSON.stringify(r));
db.failRpc = "apply_subscription_event";
const failing = JSON.stringify(whopMem("membership.activated", U1, "mem_4", "plan_pro", "active"));
r = await whop(failing, await whopHeaders(failing, "msg_fail"));
const marked = (db.tables.billing_events ?? []).some((e: any) => e.event_id === "msg_fail");
check("Whop: a failed write answers 500 and forgets the delivery", r.status === 500 && !marked, JSON.stringify(r) + marked);
db.failRpc = "";
r = await whop(failing, await whopHeaders(failing, "msg_fail"));
check("Whop: the retry is then applied", r.status === 200 && last().p_subscription_id === "mem_4", JSON.stringify(r));
n = calls();
const forged = JSON.stringify(whopMem("membership.activated", U1, "mem_5", "plan_pro", "active"));
r = await whop(forged, await whopHeaders(forged, "msg_f", undefined, "ws_wrong"));
check("Whop: a forged signature is refused", r.status === 401 && calls() === n, JSON.stringify(r));
r = await whop(forged, await whopHeaders(forged, "msg_old", Math.floor(Date.now() / 1000) - 3600));
check("Whop: a correctly signed but hour-old delivery is refused", r.status === 401 && calls() === n, JSON.stringify(r));
const tampered = await whopHeaders(forged, "msg_t");
r = await whop(forged.replace("plan_pro", "plan_xxx"), tampered);
check("Whop: a changed body is refused", r.status === 401 && calls() === n, JSON.stringify(r));

r = await paypal(paypalSub("p1", "BILLING.SUBSCRIPTION.ACTIVATED", U1, "I-1", "P-PRO", "ACTIVE", "2026-10-01T10:00:00Z"));
check("PayPal: a paid subscription is applied with our plan", last().p_provider === "paypal" && last().p_plan === "pro" && last().p_status === "active", JSON.stringify(last()));
n = calls();
r = await paypal(paypalSub("p2", "BILLING.SUBSCRIPTION.ACTIVATED", U1, "I-1", "P-UNKNOWN", "ACTIVE", "2026-10-02T10:00:00Z"));
check("PayPal: an unknown plan neither grants nor removes", r.body.ignored === "unknown_plan" && calls() === n, JSON.stringify(r));

// ---- Webhooks: refused cheaply before any work ----
n = calls();
const outboundBefore = outbound.length;
r = await paypal(paypalSub("p3", "BILLING.SUBSCRIPTION.ACTIVATED", U1, "I-1", "P-PRO", "ACTIVE", "2026-10-03T10:00:00Z"), {});
check("PayPal: no signature headers is refused without calling PayPal", r.status === 401 && outbound.length === outboundBefore && calls() === n, JSON.stringify(r));
const huge = JSON.stringify({ type: "membership.activated", pad: "x".repeat(300 * 1024) });
r = await whop(huge, await whopHeaders("{}"));
check("Whop: an oversized delivery is refused", r.status === 413 && calls() === n, JSON.stringify(r));
r = await whop(forged, {});
check("Whop: no signature headers is refused", r.status === 401 && calls() === n, JSON.stringify(r));

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
const asked = whopCheckouts[whopCheckouts.length - 1];
const oldBasic = await handlers["create-checkout"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-c6" }, body: JSON.stringify({ plan: "basic", period: "monthly" }) }));
check("Checkout: the retired Basic plan opens Pro", oldBasic.status === 200 && whopCheckouts[whopCheckouts.length - 1]?.metadata?.plan === "pro", String(oldBasic.status) + JSON.stringify(whopCheckouts[whopCheckouts.length - 1]));
check(
  "Checkout: Whop's hosted checkout for our plan, carrying the user id",
  String(r.body.url).startsWith("https://whop.com/checkout/plan_pro") && asked?.plan_id === "plan_pro" && asked?.metadata?.user_id === "c5" && asked?.metadata?.plan === "pro",
  JSON.stringify(r) + JSON.stringify(asked),
);

// ---- Founding offer: the first year of PRO yearly on its own Whop plan ----
const yearly = async (u: string) => {
  const res = await handlers["create-checkout"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-" + u }, body: JSON.stringify({ plan: "pro", period: "yearly" }) }));
  return { status: res.status, body: await res.json() };
};
const lastPlan = () => whopCheckouts[whopCheckouts.length - 1]?.plan_id;
r = await yearly("f1");
check("Founding: with no offer running, yearly is the regular plan", r.status === 200 && lastPlan() === "plan_pro_year", JSON.stringify(r) + lastPlan());
Deno.env.set("FOUNDING_OFFER_ENDS_AT", new Date(Date.now() + 86_400_000).toISOString());
r = await yearly("f2");
check("Founding: while it runs, yearly opens the founding plan", r.status === 200 && lastPlan() === "plan_pro_founding", JSON.stringify(r) + lastPlan());
r = await checkout("f3");
check("Founding: monthly stays at its regular plan", r.status === 200 && lastPlan() === "plan_pro", JSON.stringify(r) + lastPlan());
Deno.env.set("FOUNDING_OFFER_ENDS_AT", new Date(Date.now() - 1_000).toISOString());
r = await yearly("f4");
check("Founding: once it is over, yearly is the regular plan again", r.status === 200 && lastPlan() === "plan_pro_year", JSON.stringify(r) + lastPlan());
Deno.env.delete("FOUNDING_OFFER_ENDS_AT");
r = await whop(whopMem("membership.activated", U1, "mem_f", "plan_pro_founding", "active"));
check("Founding: a founding membership is PRO yearly", last().p_plan === "pro" && last().p_period === "yearly", JSON.stringify(last()));

// ---- Usage limits (BETA off: FREE = 3 scans a month, 5 lifetime AI answers) ----
const scan = () => handlers["receipt-scan"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-u7" }, body: JSON.stringify({ imageBase64: "AAAA", mimeType: "image/jpeg", v: 2 }) }));
model.reply = JSON.stringify({ r: true, inv: "", dt: "2026-10-01", cur: "USD", sym: "$", sup: "S", cus: "", cat: "x", it: [], sub: "", dis: "", tax: "", tot: "9.50", paid: "", due: "" });
model.calls = 0;
const codes = await Promise.all(Array.from({ length: 10 }, () => scan().then((x) => x.status)));
const used = db.tables.ocr_usage_monthly?.find((x: any) => x.user_id === "u7")?.scans;
check("OCR: 10 parallel scans on a 3-scan monthly allowance: 3 served", codes.filter((c) => c === 200).length === 3 && model.calls === 3 && used === 3, codes.join(",") + " calls=" + model.calls + " used=" + used);
const nextMonth = db.tables.ocr_usage_monthly.find((x: any) => x.user_id === "u7");
const thisMonth = nextMonth.month;
nextMonth.month = "2000-01";
const refilled = await scan();
check("OCR: FREE scans come back the next month", refilled.status === 200, String(refilled.status));
db.tables.ocr_usage_monthly = db.tables.ocr_usage_monthly.filter((x: any) => !(x.user_id === "u7" && x.month === "2000-01"));
nextMonth.month = thisMonth;
model.reply = JSON.stringify({ r: false });
const before = db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans;
db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans = 1;
db.tables.ocr_usage_monthly.forEach((x: any) => { if (x.user_id === "u7") x.scans = 1; });
const unreadable = await scan();
check("OCR: an unreadable photo gives its scan back", (await unreadable.json()).reason === "unreadable" && db.tables.ocr_usage_lifetime.find((x: any) => x.user_id === "u7").scans === 1, String(before));

model.reply = JSON.stringify({ r: true, inv: "", dt: "2026-10-01", cur: "USD", sym: "$", sup: "S", cus: "", cat: "x", it: [], sub: "", dis: "", tax: "", tot: "9.50", paid: "", due: "" });
model.hang = true;
const stuck = await handlers["receipt-scan"](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-u11" }, body: JSON.stringify({ imageBase64: "AAAA", mimeType: "image/jpeg", v: 2 }) }));
model.hang = false;
const stuckBody = await stuck.json();
const stuckUsed = db.tables.ocr_usage_monthly.find((x: any) => x.user_id === "u11")?.scans ?? 0;
check("OCR: a stuck model answers 'timeout' and gives the scan back", stuck.status === 504 && stuckBody.error === "timeout" && stuckUsed === 0, stuck.status + " " + JSON.stringify(stuckBody) + " used=" + stuckUsed);

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
