-- ============================================================================
-- SmartBudget — automatic sync between devices (run after abuse_limits.sql;
-- safe to re-run)
-- ----------------------------------------------------------------------------
-- The app keeps one sync document per account in user_backups (record-level
-- changes and deletions; see lib/features/sync). A version number makes each
-- upload conditional: a device writes only over the version it merged with,
-- so two devices syncing at the same moment can't overwrite each other (the
-- second one merges again and retries). Until this runs, the app uploads
-- without the check.
-- ============================================================================

alter table public.user_backups
  add column if not exists version bigint not null default 0;
