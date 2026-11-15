-- ============================================================================
-- Account tombstones (DB-10): deleting an account and signing up again with
-- the same e-mail must not bring back the one-time PRO trial or the free
-- lifetime AI and receipt-scan allowances.
--
-- Before an account is deleted, delete-account calls
-- record_account_tombstone(user): it keeps, under a SHA-256 hash of the
-- normalised e-mail (never the address itself), whether the trial was used
-- and how much of the lifetime allowances was spent. A new account with the
-- same e-mail starts from there. Kept 2 years (purge_old_rows), stated in
-- the privacy policy as fraud prevention. Safe to run again.
-- ============================================================================

create table if not exists account_tombstones (
  email_hash   text primary key,
  trial_used   boolean not null default false,
  ai_lifetime  int not null default 0,
  ocr_lifetime int not null default 0,
  deleted_at   timestamptz not null default now()
);

-- No client may read or write it (no policy): the functions below only.
alter table account_tombstones enable row level security;
revoke all on account_tombstones from anon, authenticated;

-- One person, one hash: lower case, no spaces, no "+tag", and for Gmail no
-- dots and googlemail.com = gmail.com.
create or replace function public.email_fingerprint(p_email text) returns text
language plpgsql immutable
set search_path = public, pg_temp
as $$
declare
  e text := lower(trim(coalesce(p_email, '')));
  local_part text;
  domain text;
begin
  if position('@' in e) = 0 then return null; end if;
  local_part := split_part(e, '@', 1);
  domain := split_part(e, '@', 2);
  local_part := split_part(local_part, '+', 1);
  if domain in ('gmail.com', 'googlemail.com') then
    local_part := replace(local_part, '.', '');
    domain := 'gmail.com';
  end if;
  if local_part = '' or domain = '' then return null; end if;
  return encode(sha256(convert_to(local_part || '@' || domain, 'UTF8')), 'hex');
end $$;

create or replace function public.record_account_tombstone(p_user uuid) returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  h text;
begin
  select public.email_fingerprint(email) into h from auth.users where id = p_user;
  if h is null then return; end if;
  insert into account_tombstones as t (email_hash, trial_used, ai_lifetime, ocr_lifetime, deleted_at)
  values (
    h,
    coalesce((select trial_used_at is not null from ai_entitlements where user_id = p_user), false),
    coalesce((select requests from ai_usage_lifetime where user_id = p_user), 0),
    coalesce((select scans from ocr_usage_lifetime where user_id = p_user), 0),
    now())
  on conflict (email_hash) do update set
    trial_used   = t.trial_used or excluded.trial_used,
    ai_lifetime  = greatest(t.ai_lifetime, excluded.ai_lifetime),
    ocr_lifetime = greatest(t.ocr_lifetime, excluded.ocr_lifetime),
    deleted_at   = now();
end $$;

revoke all on function public.record_account_tombstone(uuid) from public, anon, authenticated;
grant execute on function public.record_account_tombstone(uuid) to service_role;

-- A new account whose e-mail matches a tombstone starts where the deleted
-- one stopped. Never blocks a sign-up: any error is ignored.
create or replace function public.apply_account_tombstone() returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  t account_tombstones%rowtype;
begin
  begin
    select * into t from account_tombstones
      where email_hash = public.email_fingerprint(new.email);
    if not found then return new; end if;
    if t.trial_used then
      insert into ai_entitlements (user_id, trial_used_at) values (new.id, now())
        on conflict (user_id) do update
          set trial_used_at = coalesce(ai_entitlements.trial_used_at, now());
    end if;
    if t.ai_lifetime > 0 then
      insert into ai_usage_lifetime (user_id, requests) values (new.id, t.ai_lifetime)
        on conflict (user_id) do update
          set requests = greatest(ai_usage_lifetime.requests, excluded.requests);
    end if;
    if t.ocr_lifetime > 0 then
      insert into ocr_usage_lifetime (user_id, scans) values (new.id, t.ocr_lifetime)
        on conflict (user_id) do update
          set scans = greatest(ocr_usage_lifetime.scans, excluded.scans);
    end if;
  exception when others then
    raise notice 'account tombstone not applied: %', sqlerrm;
  end;
  return new;
end $$;

revoke all on function public.apply_account_tombstone() from public, anon, authenticated;

drop trigger if exists apply_account_tombstone on auth.users;
create trigger apply_account_tombstone
  after insert on auth.users
  for each row execute function public.apply_account_tombstone();
