# Anonymous error reports

So a crash is not invisible: when the app hits an **uncaught error**, it can
send the owner only *what kind of error* and *where in the app's own code* it
happened, with the app version and platform.

**Status: hidden.** Off in every build (debug included) until the owner turns
it on. Until then the app still installs last-resort error handlers (so a stray
async error is noted, not lost) but **nothing is sent**, and neither the
Settings switch nor the Privacy Policy paragraph is shown. The live database
doesn't have the table yet.

To turn it on, in this order:
1. Run `.github/workflows/supabase-error-reports.yml` by hand (Actions > Run
   workflow), or paste `supabase/error_reports.sql` in the SQL editor. Safe to
   run again. (`setup_all.sql` includes it for new projects.)
2. Build with `--dart-define=ERROR_REPORTS=true` (add it to the web build in
   `deploy-web.yml` and to `android.yml`).

## What is sent

`report_error(sig, app_version, app_platform)`, for example
`FormatException@features/budget/save.dart:42`, `1.0.0`, `android`.

- **Never** the error's message (it can quote what the user typed), the stack's
  arguments, an account, a device, an IP address or any data.
- Each signature once per session, at most 10 per session.
- Not sent: in debug builds, without a backend, or when the user turns
  **Settings > Privacy > Send anonymous error reports** off (on by default).
- A released **web** build has no Dart frames, so its signature is the error
  type plus the script position (`main.dart.js:1234:56`); it pins to one build
  because the version is sent too.
- The Privacy Policy gets a paragraph while the flag is on (the eight offered
  languages; a hidden language falls back to English).

## Reading it

Supabase dashboard > SQL editor:

```sql
select * from error_reports_recent;                -- last 7 days, most frequent first
select day, signature, version, platform, count
  from error_reports_daily order by day desc, count desc;
```

The database adds one to a day's count of a signature; a day takes at most 500
distinct signatures (a guard against junk), and clients can call the function
but cannot read or write the table (`supabase/tests/error_reports_test.sql`,
run in CI).

## Limits

Counts are a guide, not an audit (offline reports are skipped). On Android,
Play Console's *Android vitals* also shows crashes and ANRs for installs from
the store, with no code of ours.
