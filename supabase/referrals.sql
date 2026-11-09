-- ============================================================================
-- Invite friends & unlock rewards.
--
-- A member invites; every three people they invited who have each made their
-- own confirmed account and started using the app earn the inviter ONE reward
-- of their choice (up to three), permanently: at 3 friends the first pick, at 6
-- the second, at 9 the last.
--
-- WHY THIS IS SAFE TO GAME
--   Every reward is computed on the member's own device from data already on
--   it: more goals, more budgets, the salary split, the health breakdown.
--   None of them spends AI credits, OCR scans, storage or sync. So a person
--   determined enough to confirm three mailboxes of their own gains features
--   that cost DGOTIX nothing. The protections below raise the effort; the
--   choice of reward is what caps the damage.
--
-- WHAT THE CLIENT CANNOT DO
--   It has no insert, update or delete on any table here — only execute on
--   the four functions. It cannot set its own referral count, pick its own
--   referrer after the fact, or grant itself a reward.
-- ============================================================================

-- ---- One code per member ---------------------------------------------------
create table if not exists referral_codes (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  code       text not null unique,
  created_at timestamptz not null default now()
);

-- ---- One row per invited account, ever -------------------------------------
-- invitee_id is the primary key: an account can be referred once and never
-- re-attributed, which is both "no double counting" and "no changing the
-- referrer afterwards" in one constraint.
create table if not exists referrals (
  invitee_id   uuid primary key references auth.users(id) on delete cascade,
  referrer_id  uuid not null references auth.users(id) on delete cascade,
  code         text not null,
  claimed_at   timestamptz not null default now(),
  activated_at timestamptz,
  constraint referral_not_self check (invitee_id <> referrer_id)
);
create index if not exists referrals_by_referrer
  on referrals (referrer_id) where activated_at is not null;

-- ---- What a member has earned ----------------------------------------------
-- Separate from ai_entitlements on purpose: a subscription and a reward are
-- different things and must never overwrite one another.
create table if not exists reward_grants (
  user_id    uuid not null references auth.users(id) on delete cascade,
  reward     text not null,
  granted_at timestamptz not null default now(),
  primary key (user_id, reward)
);

-- ---- Nobody reaches these directly ------------------------------------------
alter table referral_codes enable row level security;
alter table referrals      enable row level security;
alter table reward_grants  enable row level security;

revoke all on table referral_codes from anon, authenticated;
revoke all on table referrals      from anon, authenticated;
revoke all on table reward_grants  from anon, authenticated;

-- Reads only, and only your own rows. Writes go through the functions below.
grant select on table referral_codes to authenticated;
grant select on table reward_grants  to authenticated;

drop policy if exists referral_codes_own on referral_codes;
create policy referral_codes_own on referral_codes
  for select to authenticated using (user_id = auth.uid());

drop policy if exists reward_grants_own on reward_grants;
create policy reward_grants_own on reward_grants
  for select to authenticated using (user_id = auth.uid());

-- referrals is never read by the client: it holds who invited whom, and the
-- progress function returns counts only, never an invited person's identity.

-- ---- The rewards, and how many picks a count earns --------------------------
-- Keep in step with ReferralReward / RewardJourney in the app
-- (lib/features/referrals).
create or replace function public.referral_rewards()
returns text[] language sql immutable as $$
  select array['salary_split', 'health_details', 'higher_limits'];
$$;

-- One pick for every three activated friends, at most one per reward.
create or replace function public.referral_picks_for(p_count int)
returns int language sql immutable as $$
  select least(3, greatest(0, p_count) / 3);
$$;

-- ---- Your code, made on first ask -------------------------------------------
create or replace function public.my_referral_code() returns text
language plpgsql security definer set search_path = public as $$
declare
  uid  uuid := auth.uid();
  existing text;
  candidate text;
begin
  if uid is null then raise exception 'not_signed_in' using errcode = '28000'; end if;

  select code into existing from referral_codes where user_id = uid;
  if existing is not null then return existing; end if;

  -- Eight characters from an alphabet without the pairs people mistype
  -- (0/O, 1/I/L), so a code can be read out loud or copied from a photo.
  for _ in 1..10 loop
    candidate := (
      select string_agg(substr('23456789ABCDEFGHJKMNPQRSTUVWXYZ',
                               1 + floor(random() * 31)::int, 1), '')
      from generate_series(1, 8)
    );
    begin
      insert into referral_codes (user_id, code) values (uid, candidate);
      return candidate;
    exception when unique_violation then
      -- Taken (or this member raced themselves): try again, or return the
      -- row the other call just wrote.
      select code into existing from referral_codes where user_id = uid;
      if existing is not null then return existing; end if;
    end;
  end loop;
  raise exception 'code_unavailable' using errcode = 'P0001';
end $$;

-- ---- A new member says who invited them -------------------------------------
-- Called once, right after the first sign-in. Refuses silently (returns false)
-- rather than raising, so a stale or mistyped code never blocks a sign-up.
create or replace function public.claim_referral(p_code text) returns boolean
language plpgsql security definer set search_path = public as $$
declare
  uid     uuid := auth.uid();
  owner   uuid;
  born    timestamptz;
begin
  if uid is null or p_code is null or length(trim(p_code)) = 0 then
    return false;
  end if;

  select user_id into owner from referral_codes
    where code = upper(trim(p_code));
  if owner is null or owner = uid then return false; end if;   -- unknown, or self

  -- Only a genuinely new account may be attributed. Someone who has used the
  -- app for a week cannot be "invited" retroactively.
  select created_at into born from auth.users where id = uid;
  if born is null or born < now() - interval '7 days' then return false; end if;

  -- The primary key makes this one-shot: a second call, by this account or a
  -- racing one, changes nothing.
  insert into referrals (invitee_id, referrer_id, code)
  values (uid, owner, upper(trim(p_code)))
  on conflict (invitee_id) do nothing;

  return found;
end $$;

-- ---- The new member starts using the app ------------------------------------
-- The caller cannot assert anything about itself that matters: the function
-- reads the confirmation state from auth.users, which only Supabase Auth
-- writes, and the reward is counted here on the server.
create or replace function public.complete_referral() returns boolean
language plpgsql security definer set search_path = public as $$
declare
  uid       uuid := auth.uid();
  confirmed timestamptz;
  ref       referrals%rowtype;
begin
  if uid is null then return false; end if;

  select email_confirmed_at into confirmed from auth.users where id = uid;
  if confirmed is null then return false; end if;      -- mailbox not proven

  update referrals set activated_at = now()
    where invitee_id = uid and activated_at is null
    returning * into ref;
  if ref.invitee_id is null then return false; end if; -- no referral, or already done

  -- Nothing is granted here any more: the inviter now CHOOSES what each three
  -- friends earn (choose_reward below), so activating only counts.
  return true;
end $$;

-- ---- The inviter picks a reward ---------------------------------------------
-- Every three activated friends earn one pick (referral_picks_for); a pick
-- cannot be repeated and the count is read on the server, never from the app.
-- Returns whether the pick was granted.
create or replace function public.choose_reward(p_reward text) returns boolean
language plpgsql security definer set search_path = public as $$
declare
  uid   uuid := auth.uid();
  done  int;
  taken int;
begin
  if uid is null then return false; end if;
  if p_reward is null or not (p_reward = any (referral_rewards())) then
    return false;
  end if;

  -- Same lock as the counting, so a pick and a late activation can't race.
  perform pg_advisory_xact_lock(hashtextextended('referral:' || uid::text, 0));
  select count(*) into done from referrals
    where referrer_id = uid and activated_at is not null;
  select count(*) into taken from reward_grants where user_id = uid;
  if taken >= referral_picks_for(done) then return false; end if;

  insert into reward_grants (user_id, reward) values (uid, p_reward)
    on conflict (user_id, reward) do nothing;
  return found;
end $$;

-- ---- What to show the inviter -----------------------------------------------
-- Counts and dates only. An invited person's id, name or e-mail never leaves
-- the server: the inviter learns that someone joined, not who.
create or replace function public.my_referral_progress()
returns table (
  joined      int,
  activated   int,
  needed      int,
  last_joined timestamptz
)
language sql security definer set search_path = public as $$
  select
    count(*)::int,
    count(*) filter (where activated_at is not null)::int,
    3,
    max(claimed_at)
  from referrals where referrer_id = auth.uid();
$$;

revoke all on function public.my_referral_code()        from public, anon;
revoke all on function public.claim_referral(text)      from public, anon;
revoke all on function public.complete_referral()       from public, anon;
revoke all on function public.choose_reward(text)        from public, anon;
revoke all on function public.my_referral_progress()    from public, anon;
revoke all on function public.referral_rewards()         from public, anon;
revoke all on function public.referral_picks_for(int)    from public, anon;

grant execute on function public.my_referral_code()     to authenticated;
grant execute on function public.claim_referral(text)   to authenticated;
grant execute on function public.complete_referral()    to authenticated;
grant execute on function public.choose_reward(text)    to authenticated;
grant execute on function public.my_referral_progress() to authenticated;
