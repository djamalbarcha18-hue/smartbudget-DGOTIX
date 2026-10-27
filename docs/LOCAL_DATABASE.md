# The device database (IndexedDB, hidden)

**Status: on** for the web (`.github/workflows/deploy-web.yml`) and the
Android app (`.github/workflows/android.yml`), since 2026-10-27. Builds made
with `--dart-define=INDEXED_DB=true` keep the user's lists (transactions,
budgets, goals, debts, projects, recurring items, wallets, wallet moves,
trips, seasons, darets, challenges, metals) in a database instead of one
SharedPreferences text per list: the browser's IndexedDB on the web, and on
Android a database file in the app's support folder (`db/smartbudget`, the
same code through sembast; «clear cache» keeps it, «clear data» or
uninstalling removes it, as with SharedPreferences). Without the flag
nothing changes.

Why: localStorage holds about 5 million characters for the whole site (a
transaction takes about 430 with its sync entry, so roughly 11,000 of them),
and every change rewrote a whole list (on Android too, where SharedPreferences
rewrites its whole file). The database has far more room and writes only the
record that changed.

## How it works

- `RecordLists` (`lib/core/storage/record_lists.dart`) is the only way the
  stores read and save their lists. `PrefsRecordLists` is the old way;
  `LocalDbRecordLists` (`local_db.dart`) is the database. `main.dart` picks
  one before anything is read (`record_lists_setup.dart`).
- Database `smartbudget`, version 1: `records` (one row per record, key
  `<list>\n<id>`, index `list`), `meta` (per list: moved in, count, amounts),
  `quarantine` (records that couldn't be read, kept instead of dropped).
- **Moving in**, list by list, the first time each is opened: copy from
  localStorage, read back, compare count, ids, every record and the amounts
  per currency; only then use it. Anything different: the list stays in
  localStorage and the next start tries again. Copying again never doubles
  a record.
- **The old copy stays.** localStorage is never cleared, and every save is
  also written there while it fits. When it no longer fits, the list is
  marked, and turning the database off first copies it back.
- **Failures are shown**: a save the database refuses brings up the
  «not saved» card (SaveHealth). No database (old browser, blocked storage):
  localStorage, as before. A session that had to save to localStorage only
  marks the list, and it is moved in again from that newer copy.
- **Upgrades**: each layout version is a step in `LocalDbRecordLists.schema`
  (never edit a released step; add one). An open tab of an older version
  closes its connection when a newer one upgrades, and then says its saves
  failed until reloaded.
- **Accounts**: rows carry the list key (`sb_txns_<account>`), so accounts
  stay apart as before; removing an account from the device also removes
  its rows. The server (Supabase RLS) is unchanged and still decides who
  sees what in the cloud.
- **Security**: IndexedDB is not encrypted; any script running on the site
  could read it, exactly like localStorage. Nothing secret goes in it (no
  password, session token, PIN or key). The protection is the site's strict
  Content-Security-Policy (no outside or inline scripts).

## Turning it on, and back off

1. `--dart-define=INDEXED_DB=true` in `DEFINES` of
   `.github/workflows/deploy-web.yml` and `.github/workflows/android.yml`.
2. To go back, remove it: on the next start the app copies back any list
   whose localStorage copy fell behind, empties the database and carries on
   as before. If that copy can't be made, it keeps using the database
   rather than show older data.

## Tests

- `test/local_db_test.dart`: moving in (verified, never doubled, unreadable
  copies, sessions without the database), saving (one record written,
  order kept, refusals shown), concurrent loads, upgrades, turning off,
  accounts, and Android's database file (kept across a restart).
- `SB_TEST_LOCAL_DB=1 flutter test` runs the other tests on the database
  (in memory). Screen tests run on a simulated clock the in-memory database
  doesn't follow, so use it with the files that have no screen tests.
- Checked in Chromium (`--dart-define=INDEXED_DB=true`): 300 transactions
  moved in with the same total, additions saved, saving with localStorage
  full, an upgrade from another tab not blocked, and turning it off
  brought every record back.
