-- ============================================================================
-- SmartBudget — launch offers: the 14-day PRO trial and the founding price
-- ----------------------------------------------------------------------------
-- • start_pro_trial(): a signed-in FREE account starts a 14-day PRO trial, once
--   ever, without a card. It only sets ai_entitlements.trial_plan /
--   trial_expires_at, which the app and the Edge Functions already honour; when
--   it lapses the account is FREE again with all its data.
-- • billing_prices.offer: marks a provider price that is only sold during an
--   offer ('founding' = the first year at the founding price). Regular prices
--   keep offer = null. create-checkout picks the founding one only while
--   FOUNDING_OFFER_ENDS_AT (an Edge Function secret) is in the future.
--
-- Apply via the Supabase SQL editor or CLI. Safe to re-run.
-- ============================================================================

-- When the account started its trial; set once, never cleared, so a trial
-- can't be started twice.
alter table ai_entitlements add column if not exists trial_used_at timestamptz;

alter table billing_prices add column if not exists offer text;

-- Starts the caller's PRO trial and returns when it ends. Refuses (errors
-- 'trial_used' / 'already_paid') when the account had one already or pays.
create or replace function public.start_pro_trial() returns timestamptz
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  ent ai_entitlements%rowtype;
  ends timestamptz := now() + interval '14 days';
begin
  if uid is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;
  insert into ai_entitlements (user_id) values (uid) on conflict (user_id) do nothing;
  select * into ent from ai_entitlements where user_id = uid for update;
  if ent.trial_used_at is not null then
    raise exception 'trial_used' using errcode = 'P0001';
  end if;
  if coalesce(ent.plan, 'free') <> 'free' then
    raise exception 'already_paid' using errcode = 'P0001';
  end if;
  update ai_entitlements
    set trial_plan = 'pro', trial_expires_at = ends, trial_used_at = now(),
        updated_at = now()
    where user_id = uid;
  return ends;
end $$;
revoke all on function public.start_pro_trial() from public, anon;
grant execute on function public.start_pro_trial() to authenticated;
