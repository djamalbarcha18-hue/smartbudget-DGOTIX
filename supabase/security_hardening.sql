-- ============================================================================
-- SmartBudget — security hardening (run after the other files; safe to re-run)
-- ----------------------------------------------------------------------------
-- 1. Usage is reserved atomically before a model is called, so parallel
--    requests can't all pass the quota check, and a platform-wide monthly
--    ceiling caps total AI and cloud-OCR spend.
-- 2. Payment webhooks remember the time of the last event applied, so an
--    older event arriving late can't undo a newer one.
-- 3. Clients can't set the (unused) plan column on their own profile.
-- 4. A cloud backup can't exceed 10 MB.
-- Until this file is run, the Edge Functions keep working as before.
-- ============================================================================

-- ---- 1. Atomic usage reservation -------------------------------------------
create index if not exists ai_usage_monthly_month_idx on ai_usage_monthly(month);
create index if not exists ocr_usage_monthly_month_idx on ocr_usage_monthly(month);

-- Counts one AI request ('ai') or cloud scan ('ocr') for the user, unless the
-- user's limit (lifetime or this month) or the platform-wide monthly limit
-- (null = none) is reached. Returns 'ok', 'quota' or 'global'.
create or replace function public.reserve_usage(
  p_user uuid,
  p_kind text,
  p_month text,
  p_limit int,
  p_lifetime boolean,
  p_global_limit int
) returns text
language plpgsql security definer set search_path = public as $$
declare
  used  int;
  total bigint;
begin
  if p_kind not in ('ai', 'ocr') then
    raise exception 'unknown usage kind %', p_kind;
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
  return 'ok';
end $$;

-- Gives back a reservation whose request then failed (never below zero).
create or replace function public.release_usage(
  p_user uuid,
  p_kind text,
  p_month text
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
  end if;
end $$;

-- Only the Edge Functions (service role) may call them.
revoke all on function public.reserve_usage(uuid, text, text, int, boolean, int)
  from public, anon, authenticated;
revoke all on function public.release_usage(uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.reserve_usage(uuid, text, text, int, boolean, int)
  to service_role;
grant execute on function public.release_usage(uuid, text, text)
  to service_role;

-- ---- 2. Webhook event ordering ---------------------------------------------
alter table subscriptions add column if not exists provider_event_at timestamptz;

-- ---- 3. Profile plan is server-only ----------------------------------------
-- Rows are created by the signup trigger; the user may change only these.
revoke insert, update on table profiles from anon, authenticated;
grant update (display_name, locale, theme, base_currency, updated_at)
  on table profiles to authenticated;

-- ---- 4. Backup size ---------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'user_backups_size'
  ) then
    alter table public.user_backups
      add constraint user_backups_size
      check (pg_column_size(data) <= 10485760) not valid;
  end if;
end $$;
