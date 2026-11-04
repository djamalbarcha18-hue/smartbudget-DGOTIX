// SmartBudget — billing helpers (provider-agnostic core).
//
// Price map, webhook idempotency and sandbox detection. The webhooks apply
// subscription changes through subscriptions.ts. Nothing here talks to a
// specific provider.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import { HttpError } from "./auth.ts";
import { normalizePlan, type Plan } from "./quota.ts";

export interface PriceMapping {
  plan: Plan;
  period: "monthly" | "yearly";
}

/**
 * Resolve a provider price id to (plan, period) via billing_prices. Webhooks
 * pass [includeRetired]: a price no longer sold still maps for the people
 * subscribed on it.
 */
export async function priceToPlan(
  db: SupabaseClient,
  priceId: string,
  provider = "whop",
  includeRetired = false,
): Promise<PriceMapping | null> {
  const { data } = await db.from("billing_prices")
    .select("plan, period, active")
    .eq("price_id", priceId).eq("provider", provider).maybeSingle();
  if (!data || (!includeRetired && data.active !== true)) return null;
  return {
    plan: normalizePlan(data.plan),
    period: data.period === "yearly" ? "yearly" : "monthly",
  };
}

/**
 * The provider price id for a (plan, period), or null. With [offer], the price
 * sold only during that offer (billing_prices.offer); without it, the regular
 * one (offer null). A database without supabase/launch_offers.sql has no offer
 * column: its one price per (plan, period) is the regular one.
 */
export async function planToPrice(
  db: SupabaseClient,
  plan: Plan,
  period: "monthly" | "yearly",
  provider = "whop",
  offer: string | null = null,
): Promise<string | null> {
  const prices = () =>
    db.from("billing_prices")
      .select("price_id").eq("plan", plan).eq("period", period)
      .eq("provider", provider).eq("active", true);
  if (offer) {
    const { data, error } = await prices().eq("offer", offer).maybeSingle();
    return error ? null : (data?.price_id as string | undefined) ?? null;
  }
  const { data, error } = await prices().is("offer", null).maybeSingle();
  if (!error) return (data?.price_id as string | undefined) ?? null;
  const old = await prices().maybeSingle();
  return (old.data?.price_id as string | undefined) ?? null;
}

/** The founding offer: the first year of PRO yearly at a lower price. */
export interface FoundingOffer {
  yearlyUsd: number;
  endsAt: string;
}

/**
 * The founding offer while it runs, from the Edge Function secrets
 * FOUNDING_OFFER_ENDS_AT (an ISO date-time; the offer stops then, or earlier
 * when the secret is removed) and FOUNDING_YEARLY_USD (default 39.99). Null
 * when unset, unparsable or over.
 */
export function foundingOffer(
  env: { endsAt?: string | null; yearlyUsd?: string | null } = {
    endsAt: Deno.env.get("FOUNDING_OFFER_ENDS_AT"),
    yearlyUsd: Deno.env.get("FOUNDING_YEARLY_USD"),
  },
  now = new Date(),
): FoundingOffer | null {
  const ends = new Date(env.endsAt ?? "");
  if (!env.endsAt || isNaN(ends.getTime()) || ends <= now) return null;
  const price = Number(env.yearlyUsd ?? "39.99");
  if (!Number.isFinite(price) || price <= 0) return null;
  return { yearlyUsd: price, endsAt: ends.toISOString() };
}

/**
 * True once, then false — records the event id so replays are ignored. Any
 * other failure throws, so the provider retries the delivery later.
 */
export async function markEventOnce(
  db: SupabaseClient,
  eventId: string,
  type: string,
  provider = "whop",
): Promise<boolean> {
  if (!eventId) return true; // no id ⇒ can't dedupe; let caller proceed
  const { error } = await db.from("billing_events")
    .insert({ event_id: eventId, type, provider });
  if (!error) return true;
  // A duplicate primary key means we've already processed this event.
  if (error.code === "23505") return false;
  throw new HttpError(500, "event_store_failed");
}

/** Forgets an event that couldn't be applied, so its retry is processed. */
export async function unmarkEvent(
  db: SupabaseClient,
  eventId: string,
): Promise<void> {
  if (!eventId) return;
  try {
    await db.from("billing_events").delete().eq("event_id", eventId);
  } catch (_) {
    // The retry will then be seen as a duplicate; logged by the caller.
  }
}

/** Whether a provider API URL is its sandbox (api-m.sandbox.paypal.com,
 * sandbox-api.whop.com). Anything unparsable counts as live. */
export function isSandboxUrl(url: string): boolean {
  try {
    return /(^|\.)sandbox[-.]/.test(new URL(url).hostname);
  } catch {
    return false;
  }
}

/** True when providers are set and each one's API URL ([urls], by provider)
 * is its sandbox, so no checkout can take real money. */
export function allSandbox(
  providers: string[],
  urls: Record<string, string>,
): boolean {
  return providers.length > 0 &&
    providers.every((p) => isSandboxUrl(urls[p] ?? ""));
}
