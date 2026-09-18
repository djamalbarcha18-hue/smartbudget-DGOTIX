-- ============================================================================
-- SmartBudget — Receipt Scanner: per-user Gemini API keys (BYOK)
-- ----------------------------------------------------------------------------
-- Security model:
--  • Each user stores THEIR OWN Gemini key. It is encrypted (AES-256-GCM) inside
--    the `save-gemini-key` Edge Function before it ever reaches Postgres — this
--    table only holds ciphertext.
--  • Row-Level Security is enabled with NO client-facing policies, so the anon
--    and authenticated roles cannot read or write this table at all. Every
--    access goes through the Edge Functions using the service role (which
--    bypasses RLS) and only after the caller's JWT has been verified.
--  • Deleting a user cascades and removes their key.
--
-- Apply via the Supabase SQL editor or CLI. Safe to re-run.
-- ============================================================================

create table if not exists user_ai_keys (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  provider   text not null default 'gemini',
  ciphertext text not null,
  updated_at timestamptz not null default now()
);

alter table user_ai_keys enable row level security;

-- Intentionally NO policies: clients (anon/authenticated) get zero access.
-- The Edge Functions use the service role, which bypasses RLS. Revoke any
-- table grants that Supabase may add by default, as defense in depth.
revoke all on table user_ai_keys from anon, authenticated;
