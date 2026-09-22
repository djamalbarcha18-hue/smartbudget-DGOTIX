-- ============================================================================
-- SmartBudget — Billing (subscriptions via a provider, default: Paddle)
-- ----------------------------------------------------------------------------
-- Provider-agnostic: the app never talks to the provider directly. A checkout
-- is created server-side (create-checkout) and the provider's webhook
-- (paddle-webhook) is the ONLY thing that grants/revokes entitlement — the
-- server stays the source of truth. Provider API keys live ONLY in Edge
-- Function secrets, never in the DB or the frontend.
--
-- Apply via the Supabase SQL editor or CLI. Safe to re-run. Requires
-- ai_gateway.sql (for ai_entitlements) to have been applied first.
-- ============================================================================

-- ---- Price map: provider price id -> (plan, period) ----------------------
-- The owner creates products/prices in the provider dashboard, then records the
-- ids here (no app release needed). This is the single mapping both checkout
-- and the webhook use, so a plan can never be granted from an unknown price.
create table if not exists billing_prices (
  price_id   text primary key,          -- provider price id (e.g. Paddle 'pri_...')
  provider   text not null default 'paddle',
  plan       text not null,             -- 'basic' | 'pro'
  period     text not null,             -- 'monthly' | 'yearly'
  active     boolean not null default true,
  updated_at timestamptz not null default now()
);

-- ---- One current subscription per user -----------------------------------
create table if not exists subscriptions (
  user_id                 uuid primary key references auth.users(id) on delete cascade,
  provider                text not null default 'paddle',
  provider_customer_id    text,
  provider_subscription_id text,
  plan                    text not null default 'free',
  period                  text,
  status                  text,          -- active | trialing | past_due | canceled | ...
  current_period_end      timestamptz,
  cancel_at_period_end    boolean not null default false,
  updated_at              timestamptz not null default now()
);

-- ---- Webhook idempotency + audit -----------------------------------------
create table if not exists billing_events (
  event_id    text primary key,          -- provider event id
  provider    text not null default 'paddle',
  type        text,
  received_at timestamptz not null default now()
);

-- ---- RLS ------------------------------------------------------------------
alter table billing_prices  enable row level security;
alter table subscriptions   enable row level security;
alter table billing_events  enable row level security;

-- Price map + events: no client access (service role only).
revoke all on table billing_prices from anon, authenticated;
revoke all on table billing_events from anon, authenticated;

-- A user may read only their own subscription (writes go through service role).
drop policy if exists subscriptions_own on subscriptions;
create policy subscriptions_own on subscriptions
  for select using (auth.uid() = user_id);

-- ---- Example seed (commented; the owner fills real provider price ids) ----
-- insert into billing_prices (price_id, plan, period) values
--   ('pri_basic_monthly', 'basic', 'monthly'),
--   ('pri_basic_yearly',  'basic', 'yearly'),
--   ('pri_pro_monthly',   'pro',   'monthly'),
--   ('pri_pro_yearly',    'pro',   'yearly')
-- on conflict (price_id) do nothing;
