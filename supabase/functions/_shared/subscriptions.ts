// SmartBudget — subscription lifecycle (provider-agnostic).
//
// Each payment webhook turns a verified provider event into one
// SubscriptionEvent about one subscription and hands it to the database
// function apply_subscription_event (supabase/subscription_lifecycle.sql).
// That function keeps every subscription separately and sets the user's plan
// to the best one still active, under a per-user lock, so an event about an
// old subscription can't undo a newer one.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import { HttpError } from "./auth.ts";
import type { Plan } from "./quota.ts";

export type SubStatus =
  | "active"
  | "trialing"
  | "past_due"
  | "paused"
  | "canceled"
  | "refunded"
  | "pending";

/** Statuses that give the subscription's plan. */
export const ENTITLING: ReadonlySet<SubStatus> = new Set(["active", "trialing"]);

export interface SubscriptionEvent {
  provider: "paddle" | "paypal";
  subscriptionId: string;
  /** Null when the event names only the subscription (refund, payment). */
  userId: string | null;
  /** Null when the event carries no price: the stored plan is kept. */
  plan: Plan | null;
  period: "monthly" | "yearly" | null;
  status: SubStatus;
  customerId?: string | null;
  periodEnd?: string | null;
  cancelAtPeriodEnd?: boolean | null;
  eventAt: string | null;
  /** A payment for the subscription just succeeded. */
  payment?: boolean;
}

export type ApplyOutcome =
  | "applied"
  | "stale"
  | "unknown_subscription"
  | "user_mismatch";

/** Applies one event; throws (so the provider retries) when it can't. */
export async function applySubscriptionEvent(
  db: SupabaseClient,
  e: SubscriptionEvent,
): Promise<ApplyOutcome> {
  const { data, error } = await db.rpc("apply_subscription_event", {
    p_provider: e.provider,
    p_subscription_id: e.subscriptionId,
    p_user: e.userId,
    p_plan: e.plan,
    p_period: e.period,
    p_status: e.status,
    p_customer_id: e.customerId ?? null,
    p_period_end: isoOrNull(e.periodEnd),
    p_cancel_at_period_end: e.cancelAtPeriodEnd ?? null,
    p_event_at: isoOrNull(e.eventAt),
    p_payment: e.payment ?? false,
  });
  if (error) throw new HttpError(500, "subscription_write_failed");
  return data as ApplyOutcome;
}

/** Paddle Billing subscription status, or null for one we don't know. */
export function paddleStatus(s: unknown): SubStatus | null {
  const v = String(s ?? "").toLowerCase();
  return v === "active" || v === "trialing" || v === "past_due" ||
      v === "paused" || v === "canceled"
    ? v
    : null;
}

/** PayPal subscription status, or null for one we don't know. */
export function paypalStatus(s: unknown): SubStatus | null {
  switch (String(s ?? "").toUpperCase()) {
    case "ACTIVE":
      return "active";
    case "SUSPENDED":
      return "paused";
    case "CANCELLED":
    case "EXPIRED":
      return "canceled";
    case "APPROVAL_PENDING":
    case "APPROVED":
      return "pending";
    default:
      return null;
  }
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** The user id our checkout attached, if it looks like one. */
export function userIdOrNull(v: unknown): string | null {
  const s = String(v ?? "").trim();
  return UUID.test(s) ? s : null;
}

/** An ISO time the database can store, or null. */
export function isoOrNull(v: unknown): string | null {
  const s = String(v ?? "").trim();
  return s && !isNaN(Date.parse(s)) ? s : null;
}
