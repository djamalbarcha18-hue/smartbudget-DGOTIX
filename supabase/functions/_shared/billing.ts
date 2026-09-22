// SmartBudget — billing helpers (provider-agnostic core).
//
// The webhook is the only thing that grants/revokes entitlement, so these
// helpers keep ai_entitlements + subscriptions in sync. Nothing here talks to a
// specific provider except verifyPaddleSignature (clearly named).
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { normalizePlan, type Plan } from "./quota.ts";

export interface PriceMapping {
  plan: Plan;
  period: "monthly" | "yearly";
}

/** Resolve a provider price id to (plan, period) via billing_prices. */
export async function priceToPlan(
  db: SupabaseClient,
  priceId: string,
): Promise<PriceMapping | null> {
  const { data } = await db.from("billing_prices")
    .select("plan, period, active").eq("price_id", priceId).maybeSingle();
  if (!data || data.active !== true) return null;
  return {
    plan: normalizePlan(data.plan),
    period: data.period === "yearly" ? "yearly" : "monthly",
  };
}

/** The provider price id for a (plan, period), or null. */
export async function planToPrice(
  db: SupabaseClient,
  plan: Plan,
  period: "monthly" | "yearly",
): Promise<string | null> {
  const { data } = await db.from("billing_prices")
    .select("price_id").eq("plan", plan).eq("period", period)
    .eq("active", true).maybeSingle();
  return (data?.price_id as string | undefined) ?? null;
}

/** Set the user's paid plan (the server source of truth for entitlement). */
export async function setEntitlementPlan(
  db: SupabaseClient,
  userId: string,
  plan: Plan,
): Promise<void> {
  await db.from("ai_entitlements").upsert({
    user_id: userId,
    plan,
    updated_at: new Date().toISOString(),
  }, { onConflict: "user_id" });
}

/** Upsert the user's current subscription snapshot. */
export async function upsertSubscription(
  db: SupabaseClient,
  row: {
    userId: string;
    provider: string;
    customerId?: string | null;
    subscriptionId?: string | null;
    plan: Plan;
    period?: string | null;
    status?: string | null;
    currentPeriodEnd?: string | null;
    cancelAtPeriodEnd?: boolean;
  },
): Promise<void> {
  await db.from("subscriptions").upsert({
    user_id: row.userId,
    provider: row.provider,
    provider_customer_id: row.customerId ?? null,
    provider_subscription_id: row.subscriptionId ?? null,
    plan: row.plan,
    period: row.period ?? null,
    status: row.status ?? null,
    current_period_end: row.currentPeriodEnd ?? null,
    cancel_at_period_end: row.cancelAtPeriodEnd ?? false,
    updated_at: new Date().toISOString(),
  }, { onConflict: "user_id" });
}

/** True once, then false — records the event id so replays are ignored. */
export async function markEventOnce(
  db: SupabaseClient,
  eventId: string,
  type: string,
  provider = "paddle",
): Promise<boolean> {
  if (!eventId) return true; // no id ⇒ can't dedupe; let caller proceed
  const { error } = await db.from("billing_events")
    .insert({ event_id: eventId, type, provider });
  // A duplicate primary key means we've already processed this event.
  return error == null;
}

/**
 * Verify a Paddle Billing webhook signature.
 * Header format: `ts=<unix>;h1=<hex hmac>`; the signed payload is
 * `${ts}:${rawBody}` HMAC-SHA256 with the webhook secret.
 */
export async function verifyPaddleSignature(
  rawBody: string,
  signatureHeader: string | null,
  secret: string,
): Promise<boolean> {
  if (!signatureHeader || !secret) return false;
  const parts = Object.fromEntries(
    signatureHeader.split(";").map((kv) => {
      const i = kv.indexOf("=");
      return [kv.slice(0, i).trim(), kv.slice(i + 1).trim()];
    }),
  );
  const ts = parts["ts"];
  const h1 = parts["h1"];
  if (!ts || !h1) return false;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${ts}:${rawBody}`),
  );
  const hex = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0")).join("");
  return timingSafeEqual(hex, h1);
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
