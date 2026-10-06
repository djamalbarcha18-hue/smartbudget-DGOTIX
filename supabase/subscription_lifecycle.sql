-- ============================================================================
-- SmartBudget — subscription lifecycle (run after security_hardening.sql;
-- safe to re-run)
-- ----------------------------------------------------------------------------
-- A user can hold more than one subscription for a while (an upgrade bought
-- before the old plan ends, a PayPal plan next to a Paddle one). Each
-- subscription is therefore kept as its own row, and every payment webhook
-- goes through apply_subscription_event(), which, under a per-user lock:
--   1. updates that one subscription (ignoring events older than the last one
--      applied to it, and never moving it to another user);
--   2. sets the user's plan to the best plan among their active subscriptions,
--      so cancelling an old Basic subscription can't take away a running Pro;
--   3. refreshes the per-user summary in `subscriptions` that the app and the
--      Manage button read.
-- A full refund or chargeback takes away that subscription's access until a
-- new billing period is paid. The Edge Functions need this file: until it
-- runs, payment webhooks answer 500 and the providers retry them later.
-- ============================================================================

create table if not exists billing_subscriptions (
  provider                 text not null,
  provider_subscription_id text not null,
  user_id                  uuid not null references auth.users(id) on delete cascade,
  plan                     text not null default 'free',   -- plan of the price on it
  period                   text,
  -- active | trialing | past_due | paused | canceled | refunded | pending
  status                   text not null,
  provider_customer_id     text,
  current_period_end       timestamptz,
  cancel_at_period_end     boolean not null default false,
  provider_event_at        timestamptz,                    -- last event applied
  updated_at               timestamptz not null default now(),
  primary key (provider, provider_subscription_id)
);
create index if not exists billing_subscriptions_user_idx
  on billing_subscriptions(user_id);

-- Server only (service role): clients read the summary in `subscriptions`.
alter table billing_subscriptions enable row level security;
revoke all on table billing_subscriptions from anon, authenticated;

-- Subscriptions recorded before this file keep their state.
insert into billing_subscriptions (provider, provider_subscription_id, user_id,
  plan, period, status, provider_customer_id, current_period_end,
  cancel_at_period_end, provider_event_at)
select provider, provider_subscription_id, user_id, plan, period,
  case lower(coalesce(status, ''))
    when 'active' then 'active' when 'trialing' then 'trialing'
    when 'past_due' then 'past_due' when 'paused' then 'paused'
    when 'suspended' then 'paused' else 'canceled' end,
  provider_customer_id, current_period_end, cancel_at_period_end,
  provider_event_at
from subscriptions
where provider_subscription_id is not null
on conflict (provider, provider_subscription_id) do nothing;

-- Applies one verified provider event to one subscription. [p_user] is null
-- when the event names only the subscription (a refund, a payment); [p_plan],
-- [p_period], [p_period_end] and [p_cancel_at_period_end] are null when the
-- event doesn't carry them (kept as they are). [p_payment]: a payment for the
-- subscription just succeeded. Returns 'applied', 'stale' (older than the last
-- event applied), 'unknown_subscription' or 'user_mismatch'.
create or replace function public.apply_subscription_event(
  p_provider text,
  p_subscription_id text,
  p_user uuid,
  p_plan text,
  p_period text,
  p_status text,
  p_customer_id text,
  p_period_end timestamptz,
  p_cancel_at_period_end boolean,
  p_event_at timestamptz,
  p_payment boolean default false
) returns text
language plpgsql security definer set search_path = public as $$
declare
  cur  billing_subscriptions%rowtype;
  had  boolean;
  uid  uuid;
  st   text := lower(coalesce(p_status, ''));
  best text;
  prim billing_subscriptions%rowtype;
begin
  if p_provider not in ('paddle', 'paypal') or coalesce(p_subscription_id, '') = '' then
    raise exception 'bad subscription event';
  end if;
  if st not in ('active', 'trialing', 'past_due', 'paused', 'canceled', 'refunded', 'pending') then
    raise exception 'unknown subscription status %', p_status;
  end if;
  if p_plan is not null and p_plan not in ('free', 'basic', 'pro') then
    raise exception 'unknown plan %', p_plan;
  end if;

  select user_id into uid from billing_subscriptions
    where provider = p_provider and provider_subscription_id = p_subscription_id;
  uid := coalesce(uid, p_user);
  if uid is null then
    return 'unknown_subscription';
  end if;

  -- One change at a time per user: the plan below is computed from all of
  -- the user's subscriptions, so two webhooks must not interleave.
  perform pg_advisory_xact_lock(hashtextextended('billing:' || uid::text, 0));

  select * into cur from billing_subscriptions
    where provider = p_provider and provider_subscription_id = p_subscription_id;
  had := found;
  if had and (cur.user_id <> uid or (p_user is not null and p_user <> cur.user_id)) then
    -- A subscription stays with the account that bought it.
    return 'user_mismatch';
  end if;
  if had and cur.provider_event_at is not null and p_event_at is not null
     and p_event_at < cur.provider_event_at then
    return 'stale';
  end if;

  if p_payment then
    -- A payment revives a failed or refunded subscription, never a cancelled one.
    if not had then
      return 'unknown_subscription';
    end if;
    st := case when cur.status = 'canceled' then 'canceled' else 'active' end;
  elsif had and cur.status = 'refunded' and st in ('active', 'trialing')
        and (p_period_end is null or cur.current_period_end is null
             or p_period_end <= cur.current_period_end) then
    -- Refunded: access comes back only with a new paid period.
    st := 'refunded';
  end if;

  insert into billing_subscriptions as b (provider, provider_subscription_id,
    user_id, plan, period, status, provider_customer_id, current_period_end,
    cancel_at_period_end, provider_event_at, updated_at)
  values (p_provider, p_subscription_id, uid, coalesce(p_plan, 'free'), p_period,
    st, p_customer_id, p_period_end, coalesce(p_cancel_at_period_end, false),
    p_event_at, now())
  on conflict (provider, provider_subscription_id) do update set
    plan                 = coalesce(p_plan, b.plan),
    period               = coalesce(p_period, b.period),
    status               = st,
    provider_customer_id = coalesce(p_customer_id, b.provider_customer_id),
    current_period_end   = coalesce(p_period_end, b.current_period_end),
    cancel_at_period_end = coalesce(p_cancel_at_period_end, b.cancel_at_period_end),
    provider_event_at    = greatest(b.provider_event_at, p_event_at),
    updated_at           = now();

  -- The plan in force: the best plan among the active subscriptions.
  select plan into best from billing_subscriptions
    where user_id = uid and status in ('active', 'trialing') and plan in ('basic', 'pro')
    order by case plan when 'pro' then 2 else 1 end desc
    limit 1;
  insert into ai_entitlements as e (user_id, plan, updated_at)
    values (uid, coalesce(best, 'free'), now())
    on conflict (user_id) do update set plan = excluded.plan, updated_at = now();

  -- The summary the app shows and Manage opens: the subscription giving the
  -- plan; else one that still bills (payment failed, paused); else the latest.
  select * into prim from billing_subscriptions
    where user_id = uid
    order by
      (status in ('active', 'trialing')) desc,
      case when status in ('active', 'trialing') and plan = 'pro' then 2
           when status in ('active', 'trialing') and plan = 'basic' then 1
           else 0 end desc,
      (status in ('past_due', 'paused')) desc,
      current_period_end desc nulls last,
      provider_event_at desc nulls last
    limit 1;
  insert into subscriptions as s (user_id, provider, provider_customer_id,
    provider_subscription_id, plan, period, status, current_period_end,
    cancel_at_period_end, provider_event_at, updated_at)
  values (uid, prim.provider, prim.provider_customer_id,
    prim.provider_subscription_id,
    case when prim.status in ('active', 'trialing', 'past_due', 'paused')
         then prim.plan else 'free' end,
    prim.period, prim.status, prim.current_period_end, prim.cancel_at_period_end,
    prim.provider_event_at, now())
  on conflict (user_id) do update set
    provider                 = excluded.provider,
    provider_customer_id     = excluded.provider_customer_id,
    provider_subscription_id = excluded.provider_subscription_id,
    plan                     = excluded.plan,
    period                   = excluded.period,
    status                   = excluded.status,
    current_period_end       = excluded.current_period_end,
    cancel_at_period_end     = excluded.cancel_at_period_end,
    provider_event_at        = excluded.provider_event_at,
    updated_at               = now();

  return 'applied';
end $$;

-- Only the payment webhooks (service role) may call it.
revoke all on function public.apply_subscription_event(text, text, uuid, text,
  text, text, text, timestamptz, boolean, timestamptz, boolean)
  from public, anon, authenticated;
grant execute on function public.apply_subscription_event(text, text, uuid, text,
  text, text, text, timestamptz, boolean, timestamptz, boolean)
  to service_role;
