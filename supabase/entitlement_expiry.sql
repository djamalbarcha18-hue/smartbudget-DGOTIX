-- ============================================================================
-- SmartBudget — entitlement expiry (run after subscription_lifecycle.sql;
-- safe to re-run)
-- ----------------------------------------------------------------------------
-- The user's plan (ai_entitlements.plan) is written when a payment webhook
-- arrives. If the "ended" webhook is late or never comes, a lapsed
-- subscription would keep Pro. This file adds a second, time-based check that
-- needs no webhook: a subscription gives its plan only while its status is
-- active/trialing AND its paid period has not ended (plus a short grace for a
-- late renewal event).
--   • refresh_entitlement(user)  recomputes one user's plan from their
--                                 subscriptions and the clock;
--   • expire_entitlements()      finds paid users with nothing still in force
--                                 and refreshes them (run hourly by pg_cron
--                                 when the extension is available).
-- Nothing here changes a table or an existing function: payment webhooks keep
-- working as before, and only service_role may call these.
-- ============================================================================

-- Days a subscription keeps its plan after current_period_end, so a renewal
-- webhook that arrives a little late doesn't flicker the plan to Free.
create or replace function public.entitlement_grace()
returns interval language sql immutable as $$ select interval '2 days' $$;

-- Recomputes one user's plan the way apply_subscription_event does, but
-- ignoring subscriptions whose paid period (plus grace) is over. Returns
-- 'downgraded', 'upgraded' or 'unchanged'. Users with no recorded
-- subscription are left alone (a plan set by hand is never touched).
create or replace function public.refresh_entitlement(p_user uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  best text;
  cur  text;
begin
  if not exists (select 1 from billing_subscriptions where user_id = p_user) then
    return 'unchanged';
  end if;

  -- Same per-user lock as apply_subscription_event: never interleave.
  perform pg_advisory_xact_lock(hashtextextended('billing:' || p_user::text, 0));

  select plan into best from billing_subscriptions
    where user_id = p_user
      and status in ('active', 'trialing')
      and plan = 'pro'
      and (current_period_end is null
           or current_period_end + public.entitlement_grace() > now())
    limit 1;
  best := coalesce(best, 'free');

  select plan into cur from ai_entitlements where user_id = p_user;
  if cur is null or cur = best then
    return 'unchanged';
  end if;

  update ai_entitlements set plan = best, updated_at = now()
    where user_id = p_user;

  -- The summary the app shows must not claim a paid plan that is over.
  if best = 'free' then
    update subscriptions set plan = 'free', updated_at = now()
      where user_id = p_user and plan <> 'free';
  end if;

  return case when best = 'free' then 'downgraded' else 'upgraded' end;
end $$;

-- Refreshes every paid user whose subscriptions no longer give that plan.
-- Returns how many users changed.
create or replace function public.expire_entitlements()
returns integer
language plpgsql security definer set search_path = public as $$
declare
  u uuid;
  n integer := 0;
begin
  for u in
    select e.user_id from ai_entitlements e
    where e.plan <> 'free'
      and exists (select 1 from billing_subscriptions b where b.user_id = e.user_id)
      and not exists (
        select 1 from billing_subscriptions b
        where b.user_id = e.user_id
          and b.status in ('active', 'trialing')
          and b.plan = e.plan
          and (b.current_period_end is null
               or b.current_period_end + public.entitlement_grace() > now()))
  loop
    if public.refresh_entitlement(u) <> 'unchanged' then
      n := n + 1;
    end if;
  end loop;
  return n;
end $$;

revoke all on function public.entitlement_grace() from public, anon, authenticated;
revoke all on function public.refresh_entitlement(uuid) from public, anon, authenticated;
revoke all on function public.expire_entitlements() from public, anon, authenticated;
grant execute on function public.entitlement_grace() to service_role;
grant execute on function public.refresh_entitlement(uuid) to service_role;
grant execute on function public.expire_entitlements() to service_role;

-- Hourly run, when pg_cron is available (Supabase: Database → Extensions).
-- Without it everything above still works; call expire_entitlements() by hand
-- or from a scheduled Edge Function instead.
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.unschedule(jobid) from cron.job where jobname = 'expire-entitlements';
    perform cron.schedule('expire-entitlements', '7 * * * *',
      'select public.expire_entitlements()');
  end if;
exception when others then
  raise notice 'pg_cron not scheduled: %', sqlerrm;
end $$;
