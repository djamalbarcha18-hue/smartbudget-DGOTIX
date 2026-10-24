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

## Budget split by item

A trip's budget is split between seven items: flights, stay, food, getting
around, activities, souvenirs & gifts, emergencies (`TripItem`,
`lib/features/trips/domain/trip_item.dart`).

- **Suggested split** by the trip's level and length (standard week:
  30 / 25 / 17 / 10 / 8 / 5 / 5 %; luxury gives more to the stay, economy
  more to emergencies; 10+ days shift from flights to stay and food, 3 days
  or fewer the other way). It follows the level and days until the user
  moves a slider; then it is saved on the trip (`split`, percent, adds up to
  100). Moving one item shares the rest out in proportion.
- **Expenses stay ordinary transactions.** Adding one inside a trip offers
  the items first; each is saved under an app category (flights → السفر,
  stay → السكن, food → المطاعم, getting around → النقل, activities →
  الترفيه, gifts → التسوق, emergencies → الطوارئ), so the month's budget and
  reports still count it. Any category reads back as an item (الطعام → food,
  الوقود → getting around, الملابس → gifts, الصحة/التأمين → emergencies…;
  the rest → other).
- **Summary:** each item's share against what it cost, over in red, and a
  tip: the item furthest over and the one with the most left to cover it
  (also on the home card while the trip is under way; hidden in percentage
  mode).
- **Internet & phone** is an item of every trip (a SIM or an eSIM plan;
  category الاتصالات والإنترنت), about 3% of the suggested split.
- **Organized trips:** "How are you travelling?" — on my own, or organized
  with an agency. An organized trip has one **package** item (flights and
  stay; السفر and السكن count under it) instead of flights and stay
  (suggested 65% in a standard week). Optional travel agency, airline and
  hotel, typed by the user and shown on the summary ("Organized with …");
  later the place to offer partners (agencies, airlines, hotels, eSIM). A
  new trip to Mecca or Medina starts as organized (Umrah and Hajj).
- Icons: Lucide line icons in the app's own icon font (SbIcons, ISC).

## Partner offers (eSIM, hotels, airlines…)

Hidden behind `PARTNER_OFFERS` (and SmartTrip). One offer at most per
screen, at the moment it helps, chosen on the device from the trip alone
(nothing about the user is sent anywhere):

| Where | When | Kinds, best first |
|---|---|---|
| Trip editor, under airline/hotel | while planning | organized: agency, hotel; else hotel, airline |
| Trip home card | the 14 days before | eSIM (no internet expense yet), insurance (no emergency expense), transport |
| Trip home card | during the trip | eSIM, transport, restaurant, activity |

Never after the trip, never in the summary or share card, no pop-ups or
notifications. Every offer says "Partner offer · for your trip to …", has
a hide button (hidden 30 days, `sb_offers_hidden`), and opens the partner's
https link with `utm_source=smartbudget`.

**Pro:** no ads. Paying subscribers (`paidProProvider`; the free launch
access doesn't count) see *booking suggestions* instead: offers with
`"audience": "pro"` and their `perk` (a discount, an extra bag…) come
first, and a partner from the user's own country (`homeCountries`, from
the country of their main currency; none for the euro) before others.
Marked "Pro suggestion from our partners", with a switch to turn them off
in Settings (`sb_pro_suggestions`). Offers with `"audience": "free"` show
on the free plan only. On the free plan an offer's `perk` shows as a
small locked line ("With Pro: …") that opens the plans.

Offers live in `assets/data/partner_offers.json` (empty until partners
sign; later the server):

```json
{"offers": [{
  "id": "acme-esim-tr", "partner": "Acme", "kind": "esim",
  "title": {"ar": "…", "en": "…"}, "body": {"ar": "…", "en": "…"},
  "url": "https://…", "countries": ["TR"], "destinations": [],
  "from": "2026-11-01", "until": "2027-03-31",
  "audience": "everyone", "homeCountries": [],
  "perk": {"ar": "…", "en": "…"}
}]}
```

Kinds: esim, hotel, airline, transport, restaurant, insurance, agency,
activity. Empty `countries` and `destinations`: anywhere. Made-up samples
show in debug builds or with `DEMO_OFFERS=true` (example.com links).

Booking is the user's business with the partner: each offer says "Booked
with the partner", and the first time one is opened a notice says that
booking and payment are with the partner, on their terms and at the user's
own responsibility, and are not part of the SmartBudget subscription or
the Pro plan (perks are the partner's). **At launch**, add the same clause
to the Terms (`legal_content.dart`, every language) under a "Partner
offers" heading.

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
