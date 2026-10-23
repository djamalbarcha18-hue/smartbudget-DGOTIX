# SmartTrip (in testing)

Trips with a destination, dates and an optional budget; expenses can be
linked to a trip. Phase 1 only: no sharing card, no trip summary, no prices.

## Where it shows

| Build | SmartTrip |
|-------|-----------|
| Debug (`flutter run`, tests) | shown |
| Any build with `--dart-define=SMART_TRIP=true` | shown |
| Google Play bundle, APKs (phone test APK included), web app | hidden |

To try it on a phone again, add `--dart-define=SMART_TRIP=true` to the
phone APK line of `.github/workflows/android.yml`.

The switch is `AppEnv.smartTrip` (`lib/core/env/app_env.dart`). Hidden means:
no "My trips" in the menu (section "Advanced features"), no `/trips` route,
no "Part of a trip" field when adding an expense.

Data is kept in every build, so nothing is lost between builds: trips are
stored like the other plans (`sb_trips_<account>`), are part of backups and
of the existing sync document (collection `trips`), and an expense carries
`tripId` only when it has one (older records simply have none).

## Destinations

`assets/data/destinations.json`: `id`, `names` (language code to name;
English is the fallback), optional `aliases` (other spellings, searched but
never shown), `country`, `icon`, `order`, optional `image`. Pictures go in
`assets/images/destinations/<id>.webp` (see `CREDITS.md` there); a place
whose picture isn't in the app shows its icon. A trip keeps its destination
as text only.

## Launching it

1. Build the store bundle with `--dart-define=SMART_TRIP=true` (or change the
   default in `AppEnv.smartTrip`).
2. Remove `AppSection.trips` from `AppNav.isLaunched`, and keep at most four
   "new" badges in the menu (`test/nav_destinations_test.dart`).
