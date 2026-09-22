-- ============================================================================
-- SmartBudget — DGOTIX AI Gateway: config, entitlement, usage, observability
-- ----------------------------------------------------------------------------
-- Used by the `ai-gateway` Edge Function. Provider keys are NOT stored here —
-- they live only in Edge Function secrets. These tables let an owner change
-- routing/kill-switches/quotas from the DB with no app release.
--
-- RLS:
--  • ai_provider_flags / ai_model_flags : world-readable (config), writes only
--    via service role or the SQL editor (owner).
--  • ai_entitlements / ai_usage_monthly : a user may READ their own row; only
--    the service role (Edge Function) writes.
--  • ai_request_log : no client access at all (service role only).
--
-- Apply via the Supabase SQL editor or CLI. Safe to re-run.
-- ============================================================================

-- ---- Provider kill switch + priority -------------------------------------
create table if not exists ai_provider_flags (
  provider_id text primary key,           -- 'google' | 'openai' | 'anthropic'
  enabled     boolean not null default true,
  priority    int,                        -- lower = preferred (null = default)
  updated_at  timestamptz not null default now()
);

-- ---- Per-model kill switch + pricing + priority --------------------------
create table if not exists ai_model_flags (
  model_id     text primary key,          -- e.g. 'gemini-flash-latest'
  provider_id  text not null,
  enabled      boolean not null default true,
  input_per_m  numeric,                   -- USD / 1M tokens (null = code default)
  output_per_m numeric,
  priority     int,
  updated_at   timestamptz not null default now()
);

-- ---- Per-user entitlement (plan) -----------------------------------------
-- The PLAN drives the limits (see supabase/functions/_shared/quota.ts, which
-- mirrors the app's FeatureCatalog). The numeric *_limit columns are kept for
-- backward-compat / rare per-user overrides but are NOT the source of truth.
create table if not exists ai_entitlements (
  user_id                uuid primary key references auth.users(id) on delete cascade,
  plan                   text not null default 'free',
  monthly_request_limit  int not null default 50,
  monthly_cost_limit_usd numeric not null default 0.50,
  updated_at             timestamptz not null default now()
);

-- Time-boxed trial: a temporarily granted higher plan that lapses back to the
-- paid plan with no data loss. Added idempotently for existing deployments.
alter table ai_entitlements add column if not exists trial_plan text;
alter table ai_entitlements add column if not exists trial_expires_at timestamptz;

-- ---- Per-user monthly usage (AI counter) ---------------------------------
create table if not exists ai_usage_monthly (
  user_id       uuid not null references auth.users(id) on delete cascade,
  month         text not null,            -- 'YYYY-MM' (UTC)
  requests      int not null default 0,
  input_tokens  bigint not null default 0,
  output_tokens bigint not null default 0,
  est_cost_usd  numeric not null default 0,
  updated_at    timestamptz not null default now(),
  primary key (user_id, month)
);

-- ---- Per-user lifetime usage (AI counter) --------------------------------
-- FREE's AI allowance is a one-time (lifetime) intro, not a monthly refill, so
-- it is enforced against this counter. Bumped on every successful answer.
create table if not exists ai_usage_lifetime (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  requests int not null default 0,
  updated_at timestamptz not null default now()
);

-- ---- Cloud OCR usage counters (monthly + lifetime) -----------------------
-- Cloud receipt OCR is metered per plan (3 / 15 / 100). On-device OCR is NOT
-- metered. These back the ocr enforcement (see quota.ts OCR_QUOTA).
create table if not exists ocr_usage_monthly (
  user_id uuid not null references auth.users(id) on delete cascade,
  month   text not null,                  -- 'YYYY-MM' (UTC)
  scans   int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, month)
);
create table if not exists ocr_usage_lifetime (
  user_id uuid primary key references auth.users(id) on delete cascade,
  scans   int not null default 0,
  updated_at timestamptz not null default now()
);

-- ---- Observability (no keys, no prompts) ---------------------------------
create table if not exists ai_request_log (
  id            bigint generated always as identity primary key,
  user_id       uuid,
  task          text,
  provider      text,
  model         text,
  fallback_used boolean default false,
  latency_ms    int,
  input_tokens  int,
  output_tokens int,
  est_cost_usd  numeric,
  error_code    text,
  created_at    timestamptz not null default now()
);

-- ---- RLS ------------------------------------------------------------------
alter table ai_provider_flags enable row level security;
alter table ai_model_flags    enable row level security;
alter table ai_entitlements   enable row level security;
alter table ai_usage_monthly  enable row level security;
alter table ai_usage_lifetime enable row level security;
alter table ocr_usage_monthly enable row level security;
alter table ocr_usage_lifetime enable row level security;
alter table ai_request_log    enable row level security;

-- Config is readable by clients (so a diagnostics screen can show it); writes
-- go through the service role / SQL editor only.
drop policy if exists ai_provider_flags_read on ai_provider_flags;
create policy ai_provider_flags_read on ai_provider_flags for select using (true);
drop policy if exists ai_model_flags_read on ai_model_flags;
create policy ai_model_flags_read on ai_model_flags for select using (true);

-- A user may read only their own entitlement + usage counters.
drop policy if exists ai_entitlements_own on ai_entitlements;
create policy ai_entitlements_own on ai_entitlements for select using (auth.uid() = user_id);
drop policy if exists ai_usage_own on ai_usage_monthly;
create policy ai_usage_own on ai_usage_monthly for select using (auth.uid() = user_id);
drop policy if exists ai_usage_life_own on ai_usage_lifetime;
create policy ai_usage_life_own on ai_usage_lifetime for select using (auth.uid() = user_id);
drop policy if exists ocr_usage_own on ocr_usage_monthly;
create policy ocr_usage_own on ocr_usage_monthly for select using (auth.uid() = user_id);
drop policy if exists ocr_usage_life_own on ocr_usage_lifetime;
create policy ocr_usage_life_own on ocr_usage_lifetime for select using (auth.uid() = user_id);

-- Logs: no client access (service role bypasses RLS). Defense in depth.
revoke all on table ai_request_log from anon, authenticated;

-- ---- Seed defaults (safe to re-run) --------------------------------------
insert into ai_provider_flags (provider_id, enabled, priority) values
  ('google', true, 1), ('openai', true, 2), ('anthropic', true, 3)
on conflict (provider_id) do nothing;
