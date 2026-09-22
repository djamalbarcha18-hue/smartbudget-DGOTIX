-- ============================================================================
-- SmartBudget — Coupons (marketing discount codes)
-- ----------------------------------------------------------------------------
-- A coupon changes the PRICE of a checkout (or grants a trial); it never itself
-- unlocks a feature — the plan does that (see docs/PRICING.md §7). Validation
-- and redemption are SERVER-SIDE ONLY (the `coupon-validate` Edge Function uses
-- the service role): coupons are NOT world-readable, so codes can't be
-- enumerated or forged from the client.
--
-- Apply via the Supabase SQL editor or CLI. Safe to re-run.
-- ============================================================================

create table if not exists coupons (
  code            text primary key,          -- stored UPPER-CASE; compared case-insensitively
  kind            text not null,             -- 'percent' | 'fixed' | 'trial_extension'
  value           numeric not null,          -- percent (0-100) | USD off | trial days
  target_plan     text,                      -- 'basic' | 'pro' | null (any)
  target_period   text,                      -- 'monthly' | 'yearly' | null (any)
  valid_from      timestamptz,               -- null = no lower bound
  valid_until     timestamptz,               -- null = no upper bound
  max_redemptions int,                       -- null = unlimited (global cap)
  per_user_limit  int not null default 1,    -- redemptions allowed per user
  active          boolean not null default true,
  note            text,                      -- internal description (campaign)
  created_at      timestamptz not null default now()
);

-- One row per successful redemption (written at checkout by the service role).
create table if not exists coupon_redemptions (
  id          bigint generated always as identity primary key,
  code        text not null references coupons(code) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  redeemed_at timestamptz not null default now()
);
create index if not exists coupon_redemptions_code_idx on coupon_redemptions(code);
create index if not exists coupon_redemptions_user_idx on coupon_redemptions(user_id);

-- ---- RLS ------------------------------------------------------------------
alter table coupons            enable row level security;
alter table coupon_redemptions enable row level security;

-- Coupons: NO client access at all (service role bypasses RLS). A user must go
-- through the coupon-validate function, which never leaks the code list.
revoke all on table coupons from anon, authenticated;

-- Redemptions: a user may read only their own (writes go through service role).
drop policy if exists coupon_redemptions_own on coupon_redemptions;
create policy coupon_redemptions_own on coupon_redemptions
  for select using (auth.uid() = user_id);

-- ---- Example seed (commented; the owner creates real campaigns) -----------
-- insert into coupons (code, kind, value, target_plan, valid_until, max_redemptions, note)
-- values ('LAUNCH25', 'percent', 25, null, now() + interval '30 days', 500, 'Launch 25% off')
-- on conflict (code) do nothing;
