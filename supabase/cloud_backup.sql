-- SmartBudget — Cloud Backup storage (Supabase / Postgres).
--
-- PURPOSE
--   Store one portable backup snapshot per signed-in user so their data can be
--   synced to their account and restored on any device. The snapshot is the
--   same backend-agnostic JSON produced by the app's local backup (BackupData),
--   stored as jsonb.
--
-- SECURITY
--   Row Level Security locks every row to its owner: a user can only read or
--   write the row whose user_id equals their auth.uid(). The anon key + the
--   user's JWT are all the client needs — no service-role key ships to the
--   frontend, and no user can see another user's data.
--
-- APPLY
--   Run this in the Supabase SQL editor (or `supabase db push`) once. The
--   feature stays dormant in the app until SUPABASE_URL/ANON_KEY are configured.

create table if not exists public.user_backups (
  user_id        uuid primary key references auth.users (id) on delete cascade,
  data           jsonb       not null,
  schema_version integer     not null default 1,
  updated_at     timestamptz not null default now()
);

alter table public.user_backups enable row level security;

-- Owner-only access. Each policy re-checks auth.uid() = user_id.
drop policy if exists "own backup - select" on public.user_backups;
create policy "own backup - select"
  on public.user_backups for select
  using (auth.uid() = user_id);

drop policy if exists "own backup - insert" on public.user_backups;
create policy "own backup - insert"
  on public.user_backups for insert
  with check (auth.uid() = user_id);

drop policy if exists "own backup - update" on public.user_backups;
create policy "own backup - update"
  on public.user_backups for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "own backup - delete" on public.user_backups;
create policy "own backup - delete"
  on public.user_backups for delete
  using (auth.uid() = user_id);
