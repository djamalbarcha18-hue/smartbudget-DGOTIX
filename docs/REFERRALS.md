# Invite friends & unlock rewards

Three people join through a member's link, confirm their mailbox and start
using the app; the member keeps a set of extra features for good.

## Why these rewards and not others

Everything a referral unlocks is **arithmetic the device already does on data
it already holds**. Nothing here spends an AI credit, an OCR scan, storage,
transfer or a sync. That is the design, not a coincidence: a determined person
can confirm three mailboxes of their own, and when they do, what they gain
costs DGOTIX nothing. The checks below raise the effort; the choice of reward
is what caps the damage.

| Unlocked | Was | Costs the server |
|---|---|---|
| Smart salary split | PRO | nothing (local maths) |
| Financial-health breakdown and advice | PRO | nothing (local maths) |
| Category budgets | 5 | unlimited — nothing |
| Goals · debts | 2 each | 5 each — nothing |
| Wallets | 2 | 4 — nothing |
| Recurring rules | 5 | 10 — nothing |
| Darets · seasons | 1 each | 3 each — nothing |

When someone reaches a counted free limit (recurring items, goals, debts,
wallets, budgets, darets, seasons) the upgrade sheet also offers "Invite 3
friends", with the number it would rise to, and a button to the invite card in
Settings. It is not shown once the reward is earned, nor for locked features
(`PlanLimits.allowAdd`, `UpgradeSheet.inviteLimit`).

The two sections a reward opens outright (smart salary split, financial-health
details) offer both choices too: their locked card and the salary-split button
show "Invite 3 friends" next to "See plans" until the reward is earned. A
locked feature that invitations do not open (reports, markets, sync...) shows
the upgrade only.

**Never granted this way:** the assistant and cloud receipt scanning (money per
call), cloud sync (storage and transfer), parallel rates and multi-currency
(our own function), PDF and advanced reports and smart alerts (what PRO sells),
priority support (the owner's time). `test/referral_rewards_test.dart` fails if
any of them is ever added.

## What counts as a referral

All five are decided on the server (`supabase/referrals.sql`):

1. the account is new — created within 7 days of the claim;
2. it signed up through the link, carrying `?ref=CODE`;
3. its **mailbox is confirmed** — read from `auth.users.email_confirmed_at`,
   which only Supabase Auth writes;
4. it is not the inviter;
5. it was never counted before — `referrals.invitee_id` is the primary key, so
   an account is attributed once and cannot be re-attributed later.

## What the client cannot do

It has **no insert, update or delete** on any referral table — only `execute`
on four functions. It cannot set its own count, pick a referrer afterwards, or
grant itself a reward. RLS lets a member read their own code and their own
grants; `referrals` is never readable from the client at all, and
`my_referral_progress()` returns counts only, so an inviter learns that someone
joined, never who.

Two invitees finishing at the same moment are serialised on a per-inviter
advisory lock, so they cannot both read "2" and leave the inviter short.

## Honest limits

A person with three real mailboxes they control can invite themselves. Stopping
that needs a phone number or identity check, which this app will not ask for.
This is why every reward is free to serve.

## Setting it up

`supabase/referrals.sql` is part of `setup_all.sql`; running that is enough.
`supabase/tests/referrals_test.sql` checks the rules against a real Postgres.

## Cost

Three small rows per referral chain and a handful of RPC calls in a member's
lifetime. Nothing recurring, nothing per-request.
