-- ============================================================================
-- Maintenance: exact usage counters, indexes, retention of growing tables,
-- and a health check of the scheduled jobs. Safe to run again.
-- ============================================================================

-- ---- Usage counters added in one statement (DB-6) -------------------------
-- The AI gateway used to read the month's row and write it back, so two
-- requests at once could lose each other's tokens and cost, and overwrite
-- the request count reserve_usage had just taken. This adds in place.
create or replace function public.add_ai_usage(
  p_user uuid,
  p_month text,
  p_requests int,
  p_input_tokens bigint,
  p_output_tokens bigint,
  p_cost numeric
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into ai_usage_monthly as m
    (user_id, month, requests, input_tokens, output_tokens, est_cost_usd, updated_at)
  values (p_user, p_month, greatest(p_requests, 0), greatest(p_input_tokens, 0),
          greatest(p_output_tokens, 0), greatest(p_cost, 0), now())
  on conflict (user_id, month) do update set
    requests      = m.requests + excluded.requests,
    input_tokens  = m.input_tokens + excluded.input_tokens,
    output_tokens = m.output_tokens + excluded.output_tokens,
    est_cost_usd  = m.est_cost_usd + excluded.est_cost_usd,
    updated_at    = now();

  if p_requests > 0 then
    insert into ai_usage_lifetime as l (user_id, requests, updated_at)
    values (p_user, p_requests, now())
    on conflict (user_id) do update set
      requests = l.requests + excluded.requests,
      updated_at = now();
  end if;
end $$;

revoke all on function public.add_ai_usage(uuid, text, int, bigint, bigint, numeric)
  from public, anon, authenticated;
grant execute on function public.add_ai_usage(uuid, text, int, bigint, bigint, numeric)
  to service_role;

-- ---- Indexes (DB-7, DB-22) ------------------------------------------------
-- Deleting an account removes its log rows by user_id; retention removes by
-- age. Without these, both scan the whole table.
create index if not exists ai_request_log_user_idx on ai_request_log (user_id);
create index if not exists ai_request_log_created_idx on ai_request_log (created_at);
create index if not exists coupon_attempts_at_idx on coupon_attempts (attempted_at);
create index if not exists referrals_referrer_idx on referrals (referrer_id);

-- ---- Retention (DB-7, DB-21) ----------------------------------------------
-- One daily clean-up with documented periods. User data (backups, reports,
-- subscriptions) is never touched here; only logs and counters.
--   ai_request_log       90 days   (per-request log: debugging and abuse)
--   coupon_attempts      30 days   (brute-force window is minutes)
--   rate_limits           2 days   (windows are minutes to a day)
--   billing_events      400 days   (a year of payment history, plus a margin)
--   error_reports_daily 180 days   (anonymous daily counts)
--   *_usage_monthly      24 months (quota history)
--   usage_pools          24 months
create or replace function public.purge_old_rows() returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  n_log int; n_coupon int; n_rate int; n_billing int; n_errors int;
  n_ai int; n_ocr int; n_pools int;
  oldest_month text := to_char(now() - interval '24 months', 'YYYY-MM');
begin
  delete from ai_request_log where created_at < now() - interval '90 days';
  get diagnostics n_log = row_count;
  delete from coupon_attempts where attempted_at < now() - interval '30 days';
  get diagnostics n_coupon = row_count;
  delete from rate_limits where window_start < now() - interval '2 days';
  get diagnostics n_rate = row_count;
  delete from billing_events where received_at < now() - interval '400 days';
  get diagnostics n_billing = row_count;
  delete from error_reports_daily where day < (now() - interval '180 days')::date;
  get diagnostics n_errors = row_count;
  delete from ai_usage_monthly where month < oldest_month;
  get diagnostics n_ai = row_count;
  delete from ocr_usage_monthly where month < oldest_month;
  get diagnostics n_ocr = row_count;
  delete from usage_pools where month < oldest_month;
  get diagnostics n_pools = row_count;
  return jsonb_build_object(
    'ai_request_log', n_log, 'coupon_attempts', n_coupon,
    'rate_limits', n_rate, 'billing_events', n_billing,
    'error_reports_daily', n_errors, 'ai_usage_monthly', n_ai,
    'ocr_usage_monthly', n_ocr, 'usage_pools', n_pools);
end $$;

revoke all on function public.purge_old_rows() from public, anon, authenticated;
grant execute on function public.purge_old_rows() to service_role;

-- ---- Are the scheduled jobs there? (DB-13) --------------------------------
-- Without pg_cron, plans never expire on time and nothing is cleaned up,
-- silently. This says which jobs exist; LAUNCH_CHECKLIST.md asks to run it.
--   select * from public.scheduled_jobs_health();
create or replace function public.scheduled_jobs_health()
returns table (job text, scheduled boolean, last_run timestamptz, last_status text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  wanted text[] := array['expire-entitlements', 'purge-old-rows'];
  j text;
begin
  foreach j in array wanted loop
    job := j;
    scheduled := false;
    last_run := null;
    last_status := null;
    begin
      execute 'select exists (select 1 from cron.job where jobname = $1)'
        into scheduled using j;
      execute 'select d.start_time, d.status from cron.job_run_details d
                 join cron.job c on c.jobid = d.jobid
                where c.jobname = $1 order by d.start_time desc limit 1'
        into last_run, last_status using j;
    exception when others then
      last_status := 'pg_cron unavailable';
    end;
    return next;
  end loop;
end $$;

revoke all on function public.scheduled_jobs_health() from public, anon, authenticated;
grant execute on function public.scheduled_jobs_health() to service_role;

-- Daily at 03:17 UTC, when pg_cron is available.
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.unschedule(jobid) from cron.job where jobname = 'purge-old-rows';
    perform cron.schedule('purge-old-rows', '17 3 * * *',
      'select public.purge_old_rows()');
  end if;
exception when others then
  raise notice 'pg_cron not scheduled: %', sqlerrm;
end $$;
