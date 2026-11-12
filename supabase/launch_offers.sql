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

-- What the account had used, all time, when its trial began. The trial's own
-- allowance (5 assistant answers, 5 cloud scans) is counted from there, so it
-- is 5 for the trial's 14 days whatever was used before it and whichever
-- months it spans (supabase/functions/_shared/quota.ts, trialAllowance).
-- Written by start_pro_trial() only; null on a trial started before this.
alter table ai_entitlements add column if not exists trial_ai_base int;
alter table ai_entitlements add column if not exists trial_ocr_base int;

alter table billing_prices add column if not exists offer text;

-- Starts the caller's PRO trial and returns when it ends. Refuses (errors
-- 'email_not_confirmed' / 'trial_used' / 'already_paid') when the account's
-- email isn't confirmed yet, had a trial already, or pays. Confirming the email
-- first keeps throwaway sign-ups from collecting trials.
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
  if not exists (select 1 from auth.users
                 where id = uid and email_confirmed_at is not null) then
    raise exception 'email_not_confirmed' using errcode = 'P0001';
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
        trial_ai_base = coalesce(
          (select requests from ai_usage_lifetime where user_id = uid), 0),
        trial_ocr_base = coalesce(
          (select scans from ocr_usage_lifetime where user_id = uid), 0),
        updated_at = now()
    where user_id = uid;
  return ends;
end $$;
revoke all on function public.start_pro_trial() from public, anon;
grant execute on function public.start_pro_trial() to authenticated;
