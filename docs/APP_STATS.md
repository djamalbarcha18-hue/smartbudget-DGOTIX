# Anonymous totals

Real numbers to show partners ("1,200 trips planned this month") without
knowing anything about anyone.

## What is sent

When a **new** trip is saved, the app calls `count_event('trip_created')`.
That is the whole request: no account, device, trip, place or amount. The
database adds one to that day's total (UTC). Editing a trip sends nothing.

- Not sent: in debug builds, without a backend, or when the user turns
  **Settings > Privacy > Count my trips anonymously** off (on by default).
- Offline, the count is skipped: the totals are a guide, not an audit.
- Anyone with the public key can call `count_event`, so a total could be
  inflated; it can't grow the database (one row per day per event).
- The Privacy Policy explains it in every language (shown with SmartTrip).

## Cost

One row per day per event: a few kilobytes a year. Well inside the free plan.

## Reading the numbers

Supabase dashboard > **Table Editor > app_stats_daily**, or in the SQL editor:

```sql
select * from app_stats_monthly;
```

Clients can't read or change the totals (supabase/tests/access_control_test.sql).

## Files

- `supabase/app_stats.sql`: the table, `count_event` and the monthly view.
  Applied to the live database by `.github/workflows/supabase-app-stats.yml`
  when it changes; also part of `setup_all.sql`.
- `lib/core/stats/app_stats.dart`: `AppStats.count`, the Settings switch.
- To count something new: add it to `StatEvent` and to the list in
  `count_event`, then say so in the Privacy Policy.

## Google Play Data safety

Nothing identifies the user and the totals are aggregated on the server.
Check Play's Data safety guidance on anonymous, aggregated data before
filling in the form, and again if anything is ever added to the request.
