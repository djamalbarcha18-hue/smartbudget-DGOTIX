// Subscription lifecycle, end to end: real Whop and PayPal webhook handlers
// (harness.ts) applying events through the real SQL function
// apply_subscription_event on Postgres (supabase/setup_all.sql applied; see
// .github/workflows/security-tests.yml). Needs PGHOST/PGUSER/PGPASSWORD.
//   deno run -A --import-map supabase/tests/import_map.json supabase/tests/subscription_lifecycle_test.ts
// Exits non-zero when a scenario fails.
import { check, db, finish, load, paypal, paypalSales, paypalSub, PRICES, sql, whop, whopHeaders, whopMem, whopMemberships } from "./harness.ts";

if (!Deno.env.get("PGHOST")) throw new Error("set PGHOST (and PGUSER/PGPASSWORD) to a database with setup_all.sql");
await load("whop-webhook", "paypal-webhook");
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

// ================================ Whop ================================
// Each event makes the webhook read the membership back from (fake) Whop,
// so whopMem() sets what Whop holds after the change, then sends its event.
{
  const u = await user();
  await whop(whopMem("membership.activated", u, "mem_A", "plan_pro_year", "active"));
  check("Whop yearly Pro: the plan is Pro", await plan(u) === "pro", await plan(u));
  await whop(whopMem("membership.activated", u, "mem_B", "plan_pro", "active"));
  check("Whop second Pro membership: Pro", await plan(u) === "pro", await plan(u));
  await whop(whopMem("membership.deactivated", u, "mem_A", "plan_pro_year", "canceled"));
  check("Whop: cancelling one membership while another runs keeps Pro", await plan(u) === "pro", await plan(u));
  check("Whop: Manage then points at the Pro membership", (await summary(u)) === "pro,active,mem_B", await summary(u));
  await whop(whopMem("membership.deactivated", u, "mem_B", "plan_pro", "canceled"));
  check("Whop: cancelling Pro (the last one) gives Free", await plan(u) === "free", await plan(u));
  check("Whop: the summary then shows no paid plan", (await summary(u)).startsWith("free,canceled,"), await summary(u));
}
{
  const u = await user();
  await whop(whopMem("membership.activated", u, "mem_C", "plan_pro_year", "active"));
  await whop(whopMem("membership.updated", u, "mem_C", "plan_pro", "active"));
  check("Whop yearly → monthly (same membership, price changed): Pro", await plan(u) === "pro", await plan(u));
  await whop(whopMem("membership.updated", u, "mem_C", "plan_pro_year", "active"));
  check("Whop monthly → yearly (same membership): Pro", await plan(u) === "pro", await plan(u));
}
{
  const u = await user();
  await whop(whopMem("membership.activated", u, "mem_D", "plan_pro", "active"));
  await whop(whopMem("membership.updated", u, "mem_D", "plan_pro", "canceling"));
  await whop(whopMem("membership.activated", u, "mem_E", "plan_pro_year", "active"));
  check("Whop new membership while the old one is set to end: Pro", await plan(u) === "pro", await plan(u));
  await whop(whopMem("membership.deactivated", u, "mem_D", "plan_pro", "expired"));
  check("Whop: still Pro on the new membership once the old one has ended", await plan(u) === "pro", await plan(u));
}
{
  const u = await user();
  await whop(whopMem("membership.activated", u, "mem_F", "plan_pro", "active"));
  const r = await whop(whopMem("membership.updated", u, "mem_F", "plan_pro", "active", { current_period_end: "2026-12-01T10:00:00Z" }));
  const end = await sql(`select to_char(current_period_end at time zone 'utc', 'YYYY-MM-DD') from subscriptions where user_id = '${u}'`);
  check("Whop renewal: still Pro, with the new renewal date", r.status === 200 && await plan(u) === "pro" && end === "2026-12-01", await plan(u) + " " + end);

  const dup = JSON.stringify(whopMem("membership.deactivated", u, "mem_F", "plan_pro", "canceled"));
  await whop(dup, await whopHeaders(dup, "msg_dup"));
  const again = await whop(dup, await whopHeaders(dup, "msg_dup"));
  check("Whop duplicate delivery: applied once", again.body.duplicate === true && await plan(u) === "free", JSON.stringify(again.body));
  // A late delivery of an earlier "active" event: Whop's current state wins.
  const late = await whop({ type: "membership.activated", data: { id: "mem_F", status: "active" } });
  check("Whop out of order: a late 'active' after the cancellation changes nothing", late.status === 200 && await plan(u) === "free", JSON.stringify(late.body) + await plan(u));
}
{
  const u = await user();
  await whop(whopMem("membership.activated", u, "mem_G", "plan_pro", "active"));
  await whop(whopMem("membership.updated", u, "mem_G", "plan_pro", "past_due"));
  check("Whop payment failure: no paid access while past due", await plan(u) === "free", await plan(u));
  check("Whop payment failure: Manage stays available to fix the card", (await summary(u)) === "pro,past_due,mem_G", await summary(u));
  whopMem("membership.updated", u, "mem_G", "plan_pro", "active");
  await whop({ type: "payment.succeeded", data: { id: "pay_G2", membership: { id: "mem_G" } } });
  check("Whop payment recovered: Pro again", await plan(u) === "pro", await plan(u));
}
{
  const u = await user();
  await whop(whopMem("membership.activated", u, "mem_H", "plan_pro", "active"));
  whopMem("membership.updated", u, "mem_H", "plan_pro", "unresolved");
  await whop({ type: "dispute.created", data: { id: "dspt_1", payment: { id: "pay_H", membership_id: "mem_H" } } });
  check("Whop dispute: no paid access while it is open", await plan(u) === "free", await plan(u));
  whopMem("membership.updated", u, "mem_H", "plan_pro", "canceled");
  await whop({ type: "refund.created", data: { id: "rfnd_H", payment: { id: "pay_H", membership_id: "mem_H" } } });
  check("Whop refund: the cancelled membership stays without access", await plan(u) === "free", await plan(u));

  const other = await user();
  const steal = await whop(whopMem("membership.updated", other, "mem_H", "plan_pro", "active", { current_period_end: "2027-01-01T10:00:00Z" }));
  check("Whop: an event can't move a membership to another account", steal.body.ignored === "user_mismatch" && await plan(other) === "none" && await plan(u) === "free", JSON.stringify(steal.body));
  delete whopMemberships["mem_unknown"];
  const orphan = await whop({ type: "refund.created", data: { id: "rfnd_x", payment: { membership_id: "mem_unknown" } } });
  check("Whop: an event about a membership Whop doesn't know is ignored", orphan.body.ignored === "unknown_membership", JSON.stringify(orphan.body));
}

// ================================ PayPal ================================
{
  const u = await user();
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-A", "P-PRO-YEAR", "ACTIVE", T(1)));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-B", "P-PRO", "ACTIVE", T(2)));
  check("PayPal second Pro subscription: Pro", await plan(u) === "pro", await plan(u));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.CANCELLED", u, "I-A", "P-PRO-YEAR", "CANCELLED", T(3)));
  check("PayPal: cancelling one subscription while another runs keeps Pro", await plan(u) === "pro", await plan(u));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.CANCELLED", u, "I-B", "P-PRO", "CANCELLED", T(4)));
  check("PayPal: cancelling Pro gives Free", await plan(u) === "free", await plan(u));
  const revive = await paypal({ id: ev(), event_type: "PAYMENT.SALE.COMPLETED", create_time: T(5), resource: { id: "S-x", billing_agreement_id: "I-B", amount: { total: "14.99" } } });
  check("PayPal: a payment never revives a cancelled subscription", revive.status === 200 && await plan(u) === "free", await plan(u));
}
{
  const u = await user();
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-C", "P-PRO", "ACTIVE", T(1)));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.UPDATED", u, "I-C", "P-PRO-YEAR", "ACTIVE", T(2)));
  check("PayPal monthly → yearly (plan revised): Pro", await plan(u) === "pro", await plan(u));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.UPDATED", u, "I-C", "P-PRO", "ACTIVE", T(3)));
  check("PayPal yearly → monthly (plan revised): Pro", await plan(u) === "pro", await plan(u));
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
  await whop(whopMem("membership.activated", u, "mem_X", "plan_pro", "active"));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-OLD", "P-PRO-YEAR", "ACTIVE", T(1, 9)));
  await paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.CANCELLED", u, "I-OLD", "P-PRO-YEAR", "CANCELLED", T(2)));
  check("Across providers: an old PayPal cancellation keeps the Whop Pro", await plan(u) === "pro", await plan(u));
}
{
  // Many events for one user at once: the plan always reflects all of them.
  const u = await user();
  await Promise.all([
    whop(whopMem("membership.activated", u, "mem_P1", "plan_pro_year", "active")),
    whop(whopMem("membership.activated", u, "mem_P2", "plan_pro", "active")),
    paypal(paypalSub(ev(), "BILLING.SUBSCRIPTION.ACTIVATED", u, "I-P3", "P-PRO-YEAR", "ACTIVE", T(1))),
  ]);
  check("Parallel webhooks for one user: the best plan wins", await plan(u) === "pro", await plan(u));
}

{
  // Expiry by the clock (supabase/entitlement_expiry.sql): no webhook needed.
  const day = 86_400_000;
  const at = (ms: number) => new Date(Date.now() + ms).toISOString();
  const refresh = async (u: string) => await sql(`select public.refresh_entitlement('${u}')`);

  const u = await user();
  await whop(whopMem("membership.activated", u, "mem_EX1", "plan_pro", "active", { current_period_end: at(10 * day) }));
  check("Expiry: a running period keeps Pro", await plan(u) === "pro" && await refresh(u) === "unchanged", await plan(u));

  const v = await user();
  await whop(whopMem("membership.activated", v, "mem_EX2", "plan_pro", "active", { current_period_end: at(-10 * day) }));
  check("Expiry: the webhook alone still says Pro", await plan(v) === "pro", await plan(v));
  check("Expiry: refresh drops a period that ended long ago", await refresh(v) === "downgraded" && await plan(v) === "free", await plan(v));
  check("Expiry: the summary no longer claims Pro", (await summary(v)).startsWith("free,"), await summary(v));

  const w = await user();
  await whop(whopMem("membership.activated", w, "mem_EX3", "plan_pro", "active", { current_period_end: at(-1 * day) }));
  check("Expiry: a late renewal inside the grace keeps Pro", await refresh(w) === "unchanged" && await plan(w) === "pro", await plan(w));

  const x = await user();
  await whop(whopMem("membership.activated", x, "mem_EX4", "plan_pro_year", "active", { current_period_end: at(-10 * day) }));
  await whop(whopMem("membership.activated", x, "mem_EX5", "plan_pro", "active", { current_period_end: at(10 * day) }));
  check("Expiry: an older membership ending doesn't touch a running Pro", await refresh(x) === "unchanged" && await plan(x) === "pro", await plan(x));

  const z = await user();
  await sql(`insert into ai_entitlements (user_id, plan) values ('${z}', 'pro')`);
  check("Expiry: a plan set by hand (no subscription) is never touched", await refresh(z) === "unchanged" && await plan(z) === "pro", await plan(z));

  const swept = Number(await sql(`select public.expire_entitlements()`));
  check("Expiry: the sweep leaves the expired user on Free", swept >= 0 && await plan(v) === "free", await plan(v));

}

finish();
