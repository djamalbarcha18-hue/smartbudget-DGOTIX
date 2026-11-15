-- ============================================================================
-- SmartBudget — daily snapshots of each account's cloud copy (run after
-- sync.sql; safe to re-run)
-- ----------------------------------------------------------------------------
-- user_backups holds ONE document per account, rewritten by every sync. A bad
-- merge or a deletion that reached the cloud could not be taken back. This
-- keeps how the document looked before its first change of each day, for the
-- last 7 days, so an account can be put back as it was (support restores it;
-- the owner can read their own snapshots).
--
-- Cost: at most one extra copy per account per day, 7 kept. The trigger does
-- a single indexed lookup on every other update of the day.
-- ============================================================================

create table if not exists public.user_backup_snapshots (
  user_id  uuid        not null references auth.users (id) on delete cascade,
  day      date        not null,
  data     jsonb       not null,
  version  bigint,
  taken_at timestamptz not null default now(),
  primary key (user_id, day)
);

alter table public.user_backup_snapshots enable row level security;

-- The owner may read their snapshots; nobody writes them from the app.
drop policy if exists "own snapshots - select" on public.user_backup_snapshots;
create policy "own snapshots - select"
  on public.user_backup_snapshots for select
  using (auth.uid() = user_id);
revoke insert, update, delete on public.user_backup_snapshots
  from anon, authenticated;

create or replace function public.snapshot_user_backup()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  today date := (now() at time zone 'utc')::date;
begin
  if not exists (select 1 from public.user_backup_snapshots
                  where user_id = old.user_id and day = today) then
    insert into public.user_backup_snapshots (user_id, day, data, version)
    values (old.user_id, today, old.data, old.version)
    on conflict (user_id, day) do nothing;
    delete from public.user_backup_snapshots
     where user_id = old.user_id and day <= today - 7;
  end if;
  return new;
end
$$;

revoke all on function public.snapshot_user_backup() from public, anon, authenticated;

drop trigger if exists user_backups_snapshot on public.user_backups;
create trigger user_backups_snapshot
  before update of data on public.user_backups
  for each row
  when (old.data is distinct from new.data)
  execute function public.snapshot_user_backup();

-- Restoring an account to day D (run by support, as the database owner):
--   update public.user_backups b
--      set data = s.data, version = b.version + 1, updated_at = now()
--     from public.user_backup_snapshots s
--    where s.user_id = b.user_id and s.user_id = '<user id>' and s.day = 'D';
-- The bumped version makes every device merge the restored copy.
