-- ============================================================================
-- SmartBudget — anonymous error counts (run after schema.sql; safe to re-run)
-- ----------------------------------------------------------------------------
-- So crashes are not invisible: when the app hits an uncaught error it sends
-- only the KIND of error and the place in the app's own code where it
-- happened ("FormatException@features/x/y.dart:42"), plus the app version and
-- platform. The database adds one to that day's count. No message, account,
-- device, IP or data is stored: one row per day per signature/version/platform.
-- The user can turn it off in Settings (Privacy).
--
-- Read it in the Supabase dashboard: Table Editor > error_reports_daily, or
--   select * from error_reports_recent;
-- Anyone with the public key can call report_error, so the counts are a
-- guide, not an audit; the table can't grow without bound (a day takes at
-- most 500 distinct signatures).
-- ============================================================================

create table if not exists error_reports_daily (
  day       date   not null,
  signature text   not null,               -- 'FormatException@features/x/y.dart:42'
  version   text   not null,               -- '1.0.0'
  platform  text   not null,               -- 'web', 'android', ...
  count     bigint not null default 0,
  primary key (day, signature, version, platform)
);
alter table error_reports_daily enable row level security;
revoke all on table error_reports_daily from anon, authenticated;

-- Adds one to today's count of a signature; anything malformed is ignored.
create or replace function report_error(sig text, app_version text, app_platform text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'utc')::date;
begin
  if sig is null or length(sig) not between 1 and 120
     or sig !~ '^[A-Za-z0-9_.:@/ -]+$' then
    return;
  end if;
  if app_version is null or app_version !~ '^[0-9]+(\.[0-9]+){0,2}$'
     or length(app_version) > 20 then
    return;
  end if;
  if app_platform is null or app_platform not in
     ('web', 'android', 'ios', 'windows', 'macos', 'linux', 'fuchsia') then
    return;
  end if;
  -- A day takes at most 500 distinct signatures (a guard against junk).
  if not exists (select 1 from error_reports_daily
                 where day = today and signature = sig
                   and version = app_version and platform = app_platform)
     and (select count(*) from error_reports_daily where day = today) >= 500 then
    return;
  end if;
  insert into error_reports_daily as e (day, signature, version, platform, count)
  values (today, sig, app_version, app_platform, 1)
  on conflict (day, signature, version, platform)
  do update set count = e.count + 1;
end $$;
revoke all on function report_error(text, text, text) from public;
grant execute on function report_error(text, text, text) to anon, authenticated;

-- The last 7 days, most frequent first, for the owner (no client access).
create or replace view error_reports_recent with (security_invoker = true) as
  select signature, version, platform, sum(count)::bigint as total,
         min(day) as first_seen, max(day) as last_seen
  from error_reports_daily
  where day >= (now() at time zone 'utc')::date - 6
  group by signature, version, platform
  order by total desc, last_seen desc;
revoke all on table error_reports_recent from anon, authenticated;
