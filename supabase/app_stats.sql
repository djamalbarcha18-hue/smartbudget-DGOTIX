-- ============================================================================
-- SmartBudget — anonymous daily totals (run after sync.sql; safe to re-run)
-- ----------------------------------------------------------------------------
-- Real numbers to show partners ("1,200 trips planned this month"), without
-- knowing anything about anyone: the app sends only the name of what
-- happened, and the database adds one to that day's total. No account,
-- device, trip, place or amount is stored — one row per day per event.
-- The user can turn it off in Settings (Privacy).
--
-- Read the totals in the Supabase dashboard: Table Editor > app_stats_daily,
-- or SQL: select * from app_stats_monthly;
-- Anyone with the public key can call count_event, so the totals are a guide,
-- not an audit; it can't grow the database (one row per day per event).
-- ============================================================================

create table if not exists app_stats_daily (
  day   date   not null,
  event text   not null,                 -- 'trip_created'
  count bigint not null default 0,
  primary key (day, event)
);
alter table app_stats_daily enable row level security;
revoke all on table app_stats_daily from anon, authenticated;

-- Adds one to today's total (UTC) of an event the app knows; anything else
-- is ignored.
create or replace function count_event(event_name text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if event_name is null or event_name not in ('trip_created') then
    return;
  end if;
  insert into app_stats_daily as s (day, event, count)
  values ((now() at time zone 'utc')::date, event_name, 1)
  on conflict (day, event) do update set count = s.count + 1;
end $$;
revoke all on function count_event(text) from public;
grant execute on function count_event(text) to anon, authenticated;

-- Totals by month, for the owner (no client access).
create or replace view app_stats_monthly with (security_invoker = true) as
  select to_char(day, 'YYYY-MM') as month, event, sum(count)::bigint as total
  from app_stats_daily
  group by 1, 2
  order by 1 desc, 2;
revoke all on table app_stats_monthly from anon, authenticated;
