# SmartTrip (in testing)

Trips with a destination, dates, travellers and an optional budget;
expenses can be linked to a trip.

- Phase 1: trips, destinations, tagging expenses, "My trips" in the menu.
- Phase 2: the home card (planning / under way / summary ready, kept 14 days
  after the trip), "Start saving for this trip" (a goal in the existing goals,
  due the day the trip starts), and the trip summary with the
  "Real value | Percentage" switch.
- Sharing: only once a trip is over ("Share your trip" on the home card's
  "summary ready" state and on the summary). When the user actually shares
  (picks an app), the trip is marked `sharedAt` and its card leaves the
  home screen; it stays in My trips.
- Clear template (paid plan, `Feature.tripPhotoCard`): the whole photo
  fills the card with light details over it (place, days, total or % used,
  the saving, three categories in one line) and the brand in one place at
  the bottom (app icon, "DGOTIX · SmartBudget", QR). Needs a photo; going
  back to the default photo with no destination picture returns to colour.
- Sizes: story 9:16 (1080 × 1920, 13% kept clear top and bottom) or feed
  post 4:5 (1080 × 1350). The photo is kept whole (only turned upright)
  and each size shows its middle with BoxFit.cover: cropped, never
  stretched. The logo and QR code never shrink, so the code always scans.
- Trip editor: start date, a days slider (1–30, longer when editing a
  longer trip; the last day follows), travellers, and an optional trip
  style (economy / mid-range / luxury) shown on the list, the summary and
  the share card. The style only describes the trip: no price estimate.
- Phase 3: the share card, a 9:16 story exported at 1080 × 1920 on the
  device (`TripShareCard`), with an optional trip photo (gallery or camera,
  kept in memory only), four colours, the logo and a QR code to
  `AppConfig.appShareUrl` (APP_SHARE_URL). `canRemoveBrandingProvider` is
  false and tied to nothing yet (for a paid plan later).

Everything is worked out on the device from the trips and the expenses that
carry `tripId`; no network call, table or service of its own.

Not done: the "trip summary ready" notification (the app has no local
notifications yet), a price estimator, and the map: postponed by the owner
until real use shows it is needed. No paid service is used. Map tile
providers' free tiers (MapTiler, Stadia) do not allow commercial use, so a
map would need a paid plan; `lat`/`lng` are already in the destinations.

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
never shown; old ones such as "Makkah" keep earlier trips recognised),
`country`, `lat`, `lng`, `icon`, `order`, optional `image`.

Choosing a place: search (every language, accents, vowel marks and hamza
forms ignored), the first six as chips with "Show all", places from earlier
trips first, or any typed text ("Use: …"). A picked place shows a card with
its country and where it came from, and is kept once confirmed. Pictures go in
`assets/images/destinations/<id>.webp` (see `CREDITS.md` there); a place
whose picture isn't in the app shows its icon. A trip keeps its destination
as text only.

## Launching it

1. Build the store bundle with `--dart-define=SMART_TRIP=true` (or change the
   default in `AppEnv.smartTrip`).
2. Remove `AppSection.trips` from `AppNav.isLaunched`, and keep at most four
   "new" badges in the menu (`test/nav_destinations_test.dart`).

## Later (owner's plans, not started)

- A dedicated smart trip page.
- Links to hotel bookings, flights and eSIM.
- Smart, non-intrusive ads.
