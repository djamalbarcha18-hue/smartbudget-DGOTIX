-- Referrals: the rules that decide a reward, checked against a real server.
-- Run after supabase_stub.sql + setup_all.sql.
\set ON_ERROR_STOP on
set client_min_messages = notice;

create or replace function assert(ok boolean, what text) returns void
language plpgsql as $$
begin
  if ok then raise notice 'PASS  %', what;
  else raise exception 'FAIL  %', what; end if;
end $$;

-- Four accounts: one inviter, three invitees. Two have confirmed mailboxes.
delete from referrals; delete from referral_codes; delete from reward_grants;
delete from auth.users where email like '%@ref.test';
insert into auth.users (id, email, created_at, email_confirmed_at) values
  ('11111111-1111-1111-1111-111111111111', 'host@ref.test',  now(), now()),
  ('22222222-2222-2222-2222-222222222222', 'one@ref.test',   now(), now()),
  ('33333333-3333-3333-3333-333333333333', 'two@ref.test',   now(), now()),
  ('44444444-4444-4444-4444-444444444444', 'three@ref.test', now(), null),
  ('55555555-5555-5555-5555-555555555555', 'old@ref.test',
     now() - interval '30 days', now());

-- ---------------------------------------------------------------- the code

select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select assert(length(my_referral_code()) = 8, 'a code is eight characters');
select assert(my_referral_code() = (select code from referral_codes
         where user_id = '11111111-1111-1111-1111-111111111111'),
       'asking twice returns the same code, never a second one');

-- ------------------------------------------------------------- self-invite
select assert(claim_referral((select code from referral_codes
         where user_id = '11111111-1111-1111-1111-111111111111')) = false,
       'a member cannot invite themselves');

-- ------------------------------------------------------------ unknown code
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select assert(claim_referral('NOSUCHCO') = false, 'an unknown code is refused');
select assert(claim_referral(null) = false, 'a null code is refused');

-- ------------------------------------------------------------------ claim
select assert(claim_referral((select code from referral_codes
         where user_id = '11111111-1111-1111-1111-111111111111')) = true,
       'a new member can name who invited them');
select assert(claim_referral((select code from referral_codes
         where user_id = '11111111-1111-1111-1111-111111111111')) = false,
       'claiming twice counts once');

-- ------------------------------------------------- an account already in use
select set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', false);
select assert(claim_referral((select code from referral_codes
         where user_id = '11111111-1111-1111-1111-111111111111')) = false,
       'an account a month old cannot be claimed as a new invite');

-- ------------------------------------------------- activation needs an inbox
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', false);
select claim_referral((select code from referral_codes
  where user_id = '11111111-1111-1111-1111-111111111111'));
select assert(complete_referral() = false,
       'an unconfirmed mailbox does not activate');

-- ------------------------------------------------------- one real activation
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select assert(complete_referral() = true, 'a confirmed invitee activates');
select assert(complete_referral() = false, 'activating twice counts once');

-- ---------------------------------------------- no reward before the third
select assert((select count(*) from reward_grants
         where user_id = '11111111-1111-1111-1111-111111111111') = 0,
       'one activation earns nothing yet');
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select assert(choose_reward('salary_split') = false,
       'a reward cannot be picked before three friends');

-- ------------------------------------------------------------ the milestone
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select claim_referral((select code from referral_codes
  where user_id = '11111111-1111-1111-1111-111111111111'));
select complete_referral();
-- Two activated; the third (44..) never confirmed, so still short.
select assert((select count(*) from reward_grants
         where user_id = '11111111-1111-1111-1111-111111111111') = 0,
       'two activations are still short of the three');

update auth.users set email_confirmed_at = now()
  where id = '44444444-4444-4444-4444-444444444444';
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', false);
select assert(complete_referral() = true, 'confirming later then activates');
select assert((select count(*) from reward_grants
         where user_id = '11111111-1111-1111-1111-111111111111') = 0,
       'the third activation grants nothing by itself: the inviter chooses');

-- ------------------------------------------------------------ choosing a pick
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select assert(choose_reward('not_a_reward') = false, 'an unknown reward is refused');
select assert(choose_reward(null) = false, 'a null reward is refused');
select assert(choose_reward('salary_split') = true,
       'three friends earn one pick, and it is granted');
select assert((select count(*) from reward_grants
         where user_id = '11111111-1111-1111-1111-111111111111') = 1,
       'exactly one reward is held after one pick');
select assert(choose_reward('health_details') = false,
       'a second pick is refused until six friends');
select assert(choose_reward('salary_split') = false,
       'the same reward cannot be picked twice');
select assert((select count(*) from reward_grants
         where user_id = '11111111-1111-1111-1111-111111111111'
           and reward = 'salary_split') = 1,
       'a reward is held once');

-- ---------------------------------------------- the picks follow the count
select assert(referral_picks_for(0) = 0 and referral_picks_for(2) = 0
          and referral_picks_for(3) = 1 and referral_picks_for(5) = 1
          and referral_picks_for(6) = 2 and referral_picks_for(9) = 3
          and referral_picks_for(30) = 3,
       'one pick per three friends, never more than the three rewards');

-- ------------------------------------------- an invitee cannot pick anything
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select assert(choose_reward('higher_limits') = false,
       'someone with no activated friends cannot pick');
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);

-- ------------------------------------------------------------- what is shown
select assert((select activated from my_referral_progress()) = 3,
       'progress reports three activated');
select assert((select needed from my_referral_progress()) = 3,
       'progress reports the target');

-- ------------------------------------------- the invitee earns nothing itself
select assert((select count(*) from reward_grants
         where user_id = '22222222-2222-2222-2222-222222222222'
           and reward = any (referral_rewards())) = 0,
       'being invited earns no inviter-side reward');
select assert((select count(*) from reward_grants
         where user_id = '22222222-2222-2222-2222-222222222222'
           and reward = 'welcome_salary_split') = 1,
       'an invited person gets the welcome gift once, when they activate');
select assert((select count(*) from reward_grants
         where user_id = '44444444-4444-4444-4444-444444444444'
           and reward = 'welcome_salary_split') = 1,
       'every activated invitee gets it');
select assert((select count(*) from reward_grants
         where user_id = '55555555-5555-5555-5555-555555555555') = 0,
       'someone who was never invited gets nothing');

-- ------------------------------ the gift never uses up the invitee's own picks
-- Give the first invitee three friends of their own: they still have a pick.
insert into auth.users (id, email, created_at, email_confirmed_at) values
  ('66666666-6666-6666-6666-666666666666', 'a@ref.test', now(), now()),
  ('77777777-7777-7777-7777-777777777777', 'b@ref.test', now(), now()),
  ('88888888-8888-8888-8888-888888888888', 'c@ref.test', now(), now());
insert into referrals (invitee_id, referrer_id, code, activated_at)
select u, '22222222-2222-2222-2222-222222222222', 'X', now()
from unnest(array['66666666-6666-6666-6666-666666666666',
                  '77777777-7777-7777-7777-777777777777',
                  '88888888-8888-8888-8888-888888888888']::uuid[]) as u;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select assert(choose_reward('higher_limits') = true,
       'the welcome gift does not use up a pick earned by three friends');

select 'ALL REFERRAL TESTS PASSED' as result;
