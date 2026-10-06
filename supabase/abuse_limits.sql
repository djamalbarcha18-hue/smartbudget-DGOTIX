-- ============================================================================
-- SmartBudget — limits against mass sign-ups (run after
-- subscription_lifecycle.sql; safe to re-run)
-- ----------------------------------------------------------------------------
-- Signing up is free, so someone can script many accounts. IP limits alone
-- don't stop that (accounts can come from many addresses), so the limits here
-- are per account and per kind of account:
--   1. Daily caps per account on AI answers and cloud scans, on top of the
--      monthly or lifetime allowance.
--   2. Shares of the platform's monthly AI/scan capacity: accounts that don't
--      pay share at most part of it, and accounts younger than a week (or not
--      confirmed) a smaller part. A crowd of fake accounts can use up only
--      its share; paying users keep the rest.
--   3. Per-account rate limits for the other costly functions (checkout,
--      subscription management, account deletion).
--   4. AI-answer reports: at most 20 per account per day.
--   5. Cloud backups of accounts younger than a week: at most 2 MB.
-- The Edge Functions choose the numbers (supabase/functions/_shared/quota.ts).
-- Until this file runs they keep the previous limits.
-- ============================================================================

-- ---- Counters (server only) -------------------------------------------------
create table if not exists usage_daily (
  user_id uuid not null references auth.users(id) on delete cascade,
  kind    text not null,                 -- 'ai' | 'ocr'
  day     date not null,
  count   int  not null default 0,
  primary key (user_id, kind, day)
);
create table if not exists usage_pools (
  kind  text not null,                   -- 'ai' | 'ocr'
  month text not null,                   -- 'YYYY-MM'
  pool  text not null,                   -- 'unpaid' | 'new'
  count int  not null default 0,
  primary key (kind, month, pool)
);
create table if not exists rate_limits (
  user_id      uuid not null references auth.users(id) on delete cascade,
  bucket       text not null,
  window_start timestamptz not null,
  count        int  not null default 0,
  primary key (user_id, bucket, window_start)
);
alter table usage_daily enable row level security;
alter table usage_pools enable row level security;
alter table rate_limits enable row level security;
revoke all on table usage_daily from anon, authenticated;
revoke all on table usage_pools from anon, authenticated;
revoke all on table rate_limits from anon, authenticated;

-- ---- Usage reservation, now with daily caps and shares -----------------------
-- Replaces the version in security_hardening.sql (same name; the new
-- arguments are optional).
drop function if exists public.reserve_usage(uuid, text, text, int, boolean, int);
drop function if exists public.release_usage(uuid, text, text);

-- Counts one AI request ('ai') or cloud scan ('ocr') for the user, unless a
-- limit is reached. Returns 'ok', 'quota' (the user's allowance), 'daily'
-- (the user's daily cap), 'global' (the platform's monthly limit) or 'pool'
-- (the monthly share for this kind of account: [p_pool] is 'paid', 'unpaid'
-- or 'new'; a 'new' request counts in both the 'new' and 'unpaid' shares).
create or replace function public.reserve_usage(
  p_user uuid,
  p_kind text,
  p_month text,
  p_limit int,
  p_lifetime boolean,
  p_global_limit int,
  p_daily_limit int default null,
  p_pool text default null,
  p_unpaid_limit int default null,
  p_new_limit int default null
) returns text
language plpgsql security definer set search_path = public as $$
declare
  used  int;
  total bigint;
  today date := (now() at time zone 'utc')::date;
begin
  if p_kind not in ('ai', 'ocr') then
    raise exception 'unknown usage kind %', p_kind;
  end if;
  if p_pool is not null and p_pool not in ('paid', 'unpaid', 'new') then
    raise exception 'unknown pool %', p_pool;
  end if;
  -- One reservation at a time per user and kind: parallel requests queue here.
  perform pg_advisory_xact_lock(hashtextextended(p_kind || ':' || p_user::text, 0));

  if p_kind = 'ai' then
    if p_lifetime then
      select requests into used from ai_usage_lifetime where user_id = p_user;
    else
      select requests into used from ai_usage_monthly
        where user_id = p_user and month = p_month;
    end if;
  else
    if p_lifetime then
      select scans into used from ocr_usage_lifetime where user_id = p_user;
    else
      select scans into used from ocr_usage_monthly
        where user_id = p_user and month = p_month;
    end if;
  end if;
  if coalesce(used, 0) >= p_limit then
    return 'quota';
  end if;

  if p_daily_limit is not null then
    select count into used from usage_daily
      where user_id = p_user and kind = p_kind and day = today;
    if coalesce(used, 0) >= p_daily_limit then
      return 'daily';
    end if;
  end if;

  if p_global_limit is not null then
    if p_kind = 'ai' then
      select coalesce(sum(requests), 0) into total from ai_usage_monthly
        where month = p_month;
    else
      select coalesce(sum(scans), 0) into total from ocr_usage_monthly
        where month = p_month;
    end if;
    if total >= p_global_limit then
      return 'global';
    end if;
  end if;

  if p_pool in ('unpaid', 'new') then
    -- The shares are shared by many users: one change at a time.
    perform pg_advisory_xact_lock(hashtextextended('pool:' || p_kind || ':' || p_month, 0));
    if p_unpaid_limit is not null then
      select count into used from usage_pools
        where kind = p_kind and month = p_month and pool = 'unpaid';
      if coalesce(used, 0) >= p_unpaid_limit then
        return 'pool';
      end if;
    end if;
    if p_pool = 'new' and p_new_limit is not null then
      select count into used from usage_pools
        where kind = p_kind and month = p_month and pool = 'new';
      if coalesce(used, 0) >= p_new_limit then
        return 'pool';
      end if;
    end if;
    insert into usage_pools as p (kind, month, pool, count)
      values (p_kind, p_month, 'unpaid', 1)
      on conflict (kind, month, pool) do update set count = p.count + 1;
    if p_pool = 'new' then
      insert into usage_pools as p (kind, month, pool, count)
        values (p_kind, p_month, 'new', 1)
        on conflict (kind, month, pool) do update set count = p.count + 1;
    end if;
  end if;

  if p_kind = 'ai' then
    insert into ai_usage_monthly as u (user_id, month, requests)
      values (p_user, p_month, 1)
      on conflict (user_id, month)
      do update set requests = u.requests + 1, updated_at = now();
    insert into ai_usage_lifetime as u (user_id, requests)
      values (p_user, 1)
      on conflict (user_id)
      do update set requests = u.requests + 1, updated_at = now();
  else
    insert into ocr_usage_monthly as u (user_id, month, scans)
      values (p_user, p_month, 1)
      on conflict (user_id, month)
      do update set scans = u.scans + 1, updated_at = now();
    insert into ocr_usage_lifetime as u (user_id, scans)
      values (p_user, 1)
      on conflict (user_id)
      do update set scans = u.scans + 1, updated_at = now();
  end if;
  insert into usage_daily as d (user_id, kind, day, count)
    values (p_user, p_kind, today, 1)
    on conflict (user_id, kind, day) do update set count = d.count + 1;
  -- Days that no longer count.
  delete from usage_daily where user_id = p_user and kind = p_kind and day < today - 7;
  return 'ok';
end $$;

-- Gives back a reservation whose request then failed (never below zero).
create or replace function public.release_usage(
  p_user uuid,
  p_kind text,
  p_month text,
  p_pool text default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_kind = 'ai' then
    update ai_usage_monthly set requests = greatest(requests - 1, 0), updated_at = now()
      where user_id = p_user and month = p_month;
    update ai_usage_lifetime set requests = greatest(requests - 1, 0), updated_at = now()
      where user_id = p_user;
  elsif p_kind = 'ocr' then
    update ocr_usage_monthly set scans = greatest(scans - 1, 0), updated_at = now()
      where user_id = p_user and month = p_month;
    update ocr_usage_lifetime set scans = greatest(scans - 1, 0), updated_at = now()
      where user_id = p_user;
  else
    return;
  end if;
  update usage_daily set count = greatest(count - 1, 0)
    where user_id = p_user and kind = p_kind and day = (now() at time zone 'utc')::date;
  if p_pool in ('unpaid', 'new') then
    update usage_pools set count = greatest(count - 1, 0)
      where kind = p_kind and month = p_month
        and (pool = 'unpaid' or (p_pool = 'new' and pool = 'new'));
  end if;
end $$;

-- ---- Per-account rate limits ----------------------------------------------------
-- Counts one call in [p_bucket] for the user; true while the user has made at
-- most [p_max] calls in the current window of [p_window_s] seconds.
create or replace function public.rate_limit_hit(
  p_user uuid,
  p_bucket text,
  p_window_s int,
  p_max int
) returns boolean
language plpgsql security definer set search_path = public as $$
declare
  win timestamptz := to_timestamp(floor(extract(epoch from now()) / p_window_s) * p_window_s);
  n   int;
begin
  insert into rate_limits as r (user_id, bucket, window_start, count)
    values (p_user, p_bucket, win, 1)
    on conflict (user_id, bucket, window_start) do update set count = r.count + 1
    returning count into n;
  delete from rate_limits
    where user_id = p_user and bucket = p_bucket and window_start < win;
  return n <= p_max;
end $$;

revoke all on function public.reserve_usage(uuid, text, text, int, boolean, int, int, text, int, int)
  from public, anon, authenticated;
revoke all on function public.release_usage(uuid, text, text, text)
  from public, anon, authenticated;
revoke all on function public.rate_limit_hit(uuid, text, int, int)
  from public, anon, authenticated;
grant execute on function public.reserve_usage(uuid, text, text, int, boolean, int, int, text, int, int)
  to service_role;
grant execute on function public.release_usage(uuid, text, text, text)
  to service_role;
grant execute on function public.rate_limit_hit(uuid, text, int, int)
  to service_role;

-- ---- AI-answer reports: at most 20 per account per day ------------------------
create index if not exists ai_reports_user_created_idx on ai_reports(user_id, created_at);
create or replace function public.ai_reports_daily_cap()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from ai_reports
      where user_id = new.user_id and created_at > now() - interval '1 day') >= 20 then
    raise exception 'too many reports today' using errcode = '54000';
  end if;
  return new;
end $$;
revoke all on function public.ai_reports_daily_cap() from public, anon, authenticated;
drop trigger if exists ai_reports_daily_cap on ai_reports;
create trigger ai_reports_daily_cap before insert on ai_reports
  for each row execute function public.ai_reports_daily_cap();

-- ---- Cloud backups of new accounts: at most 2 MB --------------------------------
create or replace function public.user_backups_new_account_size()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if pg_column_size(new.data) > 2 * 1024 * 1024 and exists (
       select 1 from auth.users
       where id = new.user_id and created_at > now() - interval '7 days') then
    raise exception 'backup too large for a new account' using errcode = '54000';
  end if;
  return new;
end $$;
revoke all on function public.user_backups_new_account_size() from public, anon, authenticated;
drop trigger if exists user_backups_new_account_size on user_backups;
create trigger user_backups_new_account_size before insert or update on user_backups
  for each row execute function public.user_backups_new_account_size();
