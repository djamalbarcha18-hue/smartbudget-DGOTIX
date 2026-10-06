// Subscription lifecycle, end to end: real Paddle and PayPal webhook handlers
// (harness.ts) applying events through the real SQL function
// apply_subscription_event on Postgres (supabase/setup_all.sql applied; see
// .github/workflows/security-tests.yml). Needs PGHOST/PGUSER/PGPASSWORD.
//   deno run -A --import-map supabase/tests/import_map.json supabase/tests/subscription_lifecycle_test.ts
// Exits non-zero when a scenario fails.
// deno-lint-ignore-file no-explicit-any
import { check, db, finish, load, paddle, paddleSub, paypal, paypalSales, paypalSub, PRICES, sql } from "./harness.ts";

if (!Deno.env.get("PGHOST")) throw new Error("set PGHOST (and PGUSER/PGPASSWORD) to a database with setup_all.sql");
await load("paddle-webhook", "paypal-webhook");
db.tables.billing_prices = PRICES;

async function user(): Promise<string> {
  const id = crypto.randomUUID();
  await sql(`insert into auth.users (id, email) values ('${id}', '${id}@test')`);
  return id;
}
const plan = (u: string) => sql(`select coalesce((select plan from ai_entitlements where user_id = '${u}'), 'none')`);
const summary = async (u: string) => (await sql(`select plan || ',' || status || ',' || provider_subscription_id from subscriptions where user_id = '${u}'`));
const T = (day: number, hour = 10) => `2026-10-${String(day).padStart(2, "0")}T${String(hour).padStart(2, "0")}:00:00Z`;
let seq = 0;
const ev = () => "evt_" + (++seq);
const period = (day: number) => ({ current_billing_period: { starts_at: T(day - 30 > 0 ? day - 30 : 1), ends_at: `2026-11-${String(day).padStart(2, "0")}T10:00:00Z` } });

// ================================ Paddle ================================
{
  const u = await user();
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_A", "pri_basic", "active", T(1)));
  check("Paddle Basic: the plan is Basic", await plan(u) === "basic", await plan(u));
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_B", "pri_pro", "active", T(2)));
  check("Paddle Basic → Pro (second subscription): Pro", await plan(u) === "pro", await plan(u));
  await paddle(paddleSub(ev(), "subscription.canceled", u, "sub_A", "pri_basic", "canceled", T(3)));
  check("Paddle: cancelling Basic while Pro runs keeps Pro", await plan(u) === "pro", await plan(u));
  check("Paddle: Manage then points at the Pro subscription", (await summary(u)) === "pro,active,sub_B", await summary(u));
  await paddle(paddleSub(ev(), "subscription.canceled", u, "sub_B", "pri_pro", "canceled", T(4)));
  check("Paddle: cancelling Pro (the last one) gives Free", await plan(u) === "free", await plan(u));
  check("Paddle: the summary then shows no paid plan", (await summary(u)).startsWith("free,canceled,"), await summary(u));
}
{
  const u = await user();
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_C", "pri_basic", "active", T(1)));
  await paddle(paddleSub(ev(), "subscription.updated", u, "sub_C", "pri_pro", "active", T(2)));
  check("Paddle Basic → Pro (same subscription, price changed): Pro", await plan(u) === "pro", await plan(u));
  await paddle(paddleSub(ev(), "subscription.updated", u, "sub_C", "pri_basic", "active", T(3)));
  check("Paddle Pro → Basic (same subscription): Basic", await plan(u) === "basic", await plan(u));
}
{
  const u = await user();
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_D", "pri_pro", "active", T(1)));
  await paddle(paddleSub(ev(), "subscription.updated", u, "sub_D", "pri_pro", "active", T(2), { scheduled_change: { action: "cancel" } }));
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_E", "pri_basic", "active", T(3)));
  check("Paddle Pro → Basic (new subscription, Pro set to end): Pro until it ends", await plan(u) === "pro", await plan(u));
  await paddle(paddleSub(ev(), "subscription.canceled", u, "sub_D", "pri_pro", "canceled", T(4)));
  check("Paddle Pro → Basic: Basic once Pro has ended", await plan(u) === "basic", await plan(u));
}
{
  const u = await user();
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_F", "pri_pro", "active", T(1), period(1)));
  const r = await paddle(paddleSub(ev(), "subscription.updated", u, "sub_F", "pri_pro", "active", T(2), { current_billing_period: { ends_at: "2026-12-01T10:00:00Z" } }));
  const end = await sql(`select to_char(current_period_end at time zone 'utc', 'YYYY-MM-DD') from subscriptions where user_id = '${u}'`);
  check("Paddle renewal: still Pro, with the new renewal date", r.status === 200 && await plan(u) === "pro" && end === "2026-12-01", await plan(u) + " " + end);

  const dup = paddleSub("evt_dup", "subscription.canceled", u, "sub_F", "pri_pro", "canceled", T(5));
  await paddle(dup);
  const again = await paddle(dup);
  check("Paddle duplicate webhook: applied once", again.body.duplicate === true && await plan(u) === "free", JSON.stringify(again.body));
  const late = await paddle(paddleSub(ev(), "subscription.updated", u, "sub_F", "pri_pro", "active", T(4)));
  check("Paddle out of order: an older 'active' after the cancellation changes nothing", late.body.ignored === "older_event" && await plan(u) === "free", JSON.stringify(late.body) + await plan(u));
}
{
  const u = await user();
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_G", "pri_pro", "active", T(1), period(1)));
  await paddle(paddleSub(ev(), "subscription.past_due", u, "sub_G", "pri_pro", "past_due", T(2)));
  check("Paddle payment failure: no paid access while past due", await plan(u) === "free", await plan(u));
  check("Paddle payment failure: Manage stays available to fix the card", (await summary(u)) === "pro,past_due,sub_G", await summary(u));
  await paddle(paddleSub(ev(), "subscription.updated", u, "sub_G", "pri_pro", "active", T(3), period(1)));
  check("Paddle payment recovered: Pro again", await plan(u) === "pro", await plan(u));
}
{
  const u = await user();
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_H", "pri_pro", "active", T(1), period(1)));
  const refund = (status: string, type = "full", action = "refund") =>
    ({ event_id: ev(), event_type: "adjustment.updated", occurred_at: T(2), data: { action, type, status, subscription_id: "sub_H" } });
  await paddle(refund("approved"));
  check("Paddle full refund: the plan is taken away", await plan(u) === "free", await plan(u));
  await paddle(paddleSub(ev(), "subscription.updated", u, "sub_H", "pri_pro", "active", T(3), period(1)));
  check("Paddle refund: an update for the same (refunded) period doesn't restore it", await plan(u) === "free", await plan(u));
  await paddle(paddleSub(ev(), "subscription.updated", u, "sub_H", "pri_pro", "active", T(4), { current_billing_period: { ends_at: "2026-12-01T10:00:00Z" } }));
  check("Paddle refund: a newly paid period restores it", await plan(u) === "pro", await plan(u));
  const cb = await paddle({ event_id: ev(), event_type: "adjustment.created", occurred_at: T(5), data: { action: "chargeback", type: "full", status: "approved", subscription_id: "sub_H" } });
  check("Paddle chargeback: the plan is taken away", cb.status === 200 && await plan(u) === "free", await plan(u));

  const other = await user();
  const steal = await paddle(paddleSub(ev(), "subscription.updated", other, "sub_H", "pri_pro", "active", T(6), { current_billing_period: { ends_at: "2027-01-01T10:00:00Z" } }));
  check("Paddle: an event can't move a subscription to another account", steal.body.ignored === "user_mismatch" && await plan(other) === "none" && await plan(u) === "free", JSON.stringify(steal.body));
  const orphan = await paddle({ event_id: ev(), event_type: "adjustment.updated", occurred_at: T(6), data: { action: "refund", type: "full", status: "approved", subscription_id: "sub_unknown" } });
  check("Paddle: a refund for a subscription we never saw is ignored", orphan.body.ignored === "unknown_subscription", JSON.stringify(orphan.body));
}

// ================================ PayPal ================================
{
  const u = await user();
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-A", "P-BASIC", "ACTIVE", T(1)));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-B", "P-PRO", "ACTIVE", T(2)));
  check("PayPal Basic → Pro (second subscription): Pro", await plan(u) === "pro", await plan(u));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.CANCELLED", u, "I-A", "P-BASIC", "CANCELLED", T(3)));
  check("PayPal: cancelling Basic while Pro runs keeps Pro", await plan(u) === "pro", await plan(u));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.CANCELLED", u, "I-B", "P-PRO", "CANCELLED", T(4)));
  check("PayPal: cancelling Pro gives Free", await plan(u) === "free", await plan(u));
  const revive = await paypal({ id: ev(), event_type: "PAYMENT.SALE.COMPLETED", create_time: T(5), resource: { id: "S-x", billing_agreement_id: "I-B", amount: { total: "14.99" } } });
  check("PayPal: a payment never revives a cancelled subscription", revive.status === 200 && await plan(u) === "free", await plan(u));
}
{
  const u = await user();
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-C", "P-PRO", "ACTIVE", T(1)));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.UPDATED", u, "I-C", "P-BASIC", "ACTIVE", T(2)));
  check("PayPal Pro → Basic (plan revised): Basic", await plan(u) === "basic", await plan(u));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.UPDATED", u, "I-C", "P-PRO", "ACTIVE", T(3)));
  check("PayPal Basic → Pro (plan revised): Pro", await plan(u) === "pro", await plan(u));
  const renew = await paypal({ id: ev(), event_type: "PAYMENT.SALE.COMPLETED", create_time: T(4), resource: { id: "S-1", billing_agreement_id: "I-C", amount: { total: "14.99" } } });
  check("PayPal renewal payment: still Pro", renew.status === 200 && await plan(u) === "pro", await plan(u));

  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.PAYMENT.FAILED", u, "I-C", "P-PRO", "ACTIVE", T(5)));
  check("PayPal payment failure: no paid access", await plan(u) === "free", await plan(u));
  check("PayPal payment failure: Manage stays available", (await summary(u)) === "pro,past_due,I-C", await summary(u));
  await paypal({ id: ev(), event_type: "PAYMENT.SALE.COMPLETED", create_time: T(6), resource: { id: "S-2", billing_agreement_id: "I-C", amount: { total: "14.99" } } });
  check("PayPal payment recovered: Pro again", await plan(u) === "pro", await plan(u));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.SUSPENDED", u, "I-C", "P-PRO", "SUSPENDED", T(7)));
  check("PayPal suspended: no paid access", await plan(u) === "free", await plan(u));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.RE-ACTIVATED", u, "I-C", "P-PRO", "ACTIVE", T(8)));
  check("PayPal re-activated: Pro again", await plan(u) === "pro", await plan(u));

  const late = await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.SUSPENDED", u, "I-C", "P-PRO", "SUSPENDED", T(7, 9)));
  check("PayPal out of order: an older suspension changes nothing", late.body.ignored === "older_event" && await plan(u) === "pro", JSON.stringify(late.body));
  const dup = paypalSub("pp_dup", "BILLING.SUBSCRIPTION.UPDATED", u, "I-C", "P-PRO", "ACTIVE", T(9));
  await paypal(dup);
  const again = await paypal(dup);
  check("PayPal duplicate webhook: applied once", again.body.duplicate === true, JSON.stringify(again.body));

  paypalSales["S-3"] = { id: "S-3", billing_agreement_id: "I-C", amount: { total: "14.99" } };
  const partial = await paypal({ id: ev(), event_type: "PAYMENT.SALE.REFUNDED", create_time: T(10), resource: { id: "R-1", sale_id: "S-3", amount: { total: "5.00" } } });
  check("PayPal partial refund: changes nothing", partial.body.ignored === "partial_refund" && await plan(u) === "pro", JSON.stringify(partial.body));
  await paypal({ id: ev(), event_type: "PAYMENT.SALE.REFUNDED", create_time: T(11), resource: { id: "R-2", sale_id: "S-3", amount: { total: "14.99" } } });
  check("PayPal full refund: the plan is taken away", await plan(u) === "free", await plan(u));
  await paypal({ id: ev(), event_type: "PAYMENT.SALE.COMPLETED", create_time: T(12), resource: { id: "S-4", billing_agreement_id: "I-C", amount: { total: "14.99" } } });
  check("PayPal refund: the next paid period restores it", await plan(u) === "pro", await plan(u));
  await paypal({ id: ev(), event_type: "PAYMENT.SALE.REVERSED", create_time: T(13), resource: { id: "S-4", billing_agreement_id: "I-C", amount: { total: "14.99" } } });
  check("PayPal chargeback: the plan is taken away", await plan(u) === "free", await plan(u));
}
{
  const u = await user();
  await paddle(paddleSub(ev(), "subscription.activated", u, "sub_X", "pri_pro", "active", T(1)));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-OLD", "P-BASIC", "ACTIVE", T(1, 9)));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.CANCELLED", u, "I-OLD", "P-BASIC", "CANCELLED", T(2)));
  check("Across providers: an old PayPal cancellation keeps the Paddle Pro", await plan(u) === "pro", await plan(u));
}
{
  // Many events for one user at once: the plan always reflects all of them.
  const u = await user();
  await Promise.all([
    paddle(paddleSub(ev(), "subscription.activated", u, "sub_P1", "pri_basic", "active", T(1))),
    paddle(paddleSub(ev(), "subscription.activated", u, "sub_P2", "pri_pro", "active", T(1))),
    paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-P3", "P-BASIC", "ACTIVE", T(1))),
  ]);
  check("Parallel webhooks for one user: the best plan wins", await plan(u) === "pro", await plan(u));
}

finish();
