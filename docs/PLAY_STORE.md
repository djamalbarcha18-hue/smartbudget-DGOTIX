# Publishing SmartBudget on Google Play

The Android app is the same Flutter code as the web app, built with
`--dart-define=STORE_BUILD=true`:

- everything is unlocked and no outside payment is offered (Google Play only
  allows Play Billing for digital subscriptions sold in an app);
- developer tools (sample data) and the web "install" card are hidden.

## 1. Upload key (once)

Google Play signs the app for users ("Play App Signing"); you sign what you
upload with your own **upload key**. If it is ever lost, Google can reset it,
but keep it safe and never commit it.

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks > upload-keystore.b64   # macOS: base64 -i …
```

Add these repository secrets (GitHub → Settings → Secrets and variables →
Actions):

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | contents of `upload-keystore.b64` |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | the key password |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | optional, as for the web build |

## 2. Build

Every push to `main` runs **Android build** (`.github/workflows/android.yml`);
it can also be started by hand (Actions → Android build → Run workflow). The
run's `smartbudget-android` artifact holds:

- `app-release.aab`: upload this to Google Play;
- `app-release.apk`: install directly on a phone to test.

Without the secrets the files are signed with a debug key: fine for testing,
refused by Google Play.

Each upload to Google Play needs a higher version code: bump `version` in
`pubspec.yaml` (`1.0.0+1` → `1.0.1+2`) and `AppConfig.version`.

## 3. Google Play Console

1. Developer account (one-time fee), identity verification.
2. Create the app: name **SmartBudget**, default language Arabic (add
   English), app, free.
3. **Closed testing first.** New personal developer accounts must run a closed
   test with at least 12 testers for 14 days before production. Create the
   closed track, add testers' emails (or a Google Group), upload the `.aab`.
4. Store listing, ready in eight languages under
   `fastlane/metadata/android/<language>/` (Arabic `ar`, English `en-US`,
   French `fr-FR`, Indonesian `id`, Spanish `es-419`, Turkish `tr-TR`, Malay
   `ms-MY`, Urdu `ur`; add each language in Play Console → Main store listing
   → Manage translations, then paste its texts and upload its images):
   - `title.txt` (≤ 30 characters), `short_description.txt` (≤ 80),
     `full_description.txt` (≤ 4000)
   - `images/phoneScreenshots/`: 8 captioned phone screenshots, 1080×1920,
     from the real app with a fictional demo person, in that language and a
     local currency
   - app icon 512×512: `assets/launcher/play_store_icon_512.png`
   - feature graphic 1024×500: `assets/launcher/play_feature_graphic.png`
   - **support e-mail**: `support@dgotix.com`
     (forwarded to the owner's Gmail by Namecheap)
   The texts describe only what the store build does (no plans or prices) and
   avoid rankings and superlatives, which Google Play doesn't allow.
5. Policy pages (public, no sign-in needed):
   - Privacy policy: `https://dgotix.com/privacy.html` (all eight languages on
     one page)
   - Account deletion: the same page, section "Deleting your account and
     data" (in-app: Settings → Account → Delete my account; on the web, sign in
     and do the same).

## 4. App content forms (Play Console → Policy → App content)

- **Ads:** no ads.
- **Target audience:** 18+.
- **Content rating:** questionnaire, category "Utility / productivity".
- **Financial features:** personal budgeting and expense tracking only; no
  loans, no payments, no investing, no crypto trading.
- **Government app / news / health:** no.
- **Data safety** (what leaves the device, and only when the user uses it):

| Data | Collected | Why | Notes |
|---|---|---|---|
| E-mail address | yes, with sign-in (Supabase) | account | not shared |
| Financial info (budget data) | only with cloud backup or the AI assistant | backup, app functionality | encrypted in transit, deletable; the assistant gets totals by month and category (amounts and dates, no descriptions or names), passed to the AI provider and not stored |
| Photos (receipt images) | only with cloud receipt scan | app functionality | sent to the AI provider through our server, not stored |
| App interactions: AI questions | only with the AI assistant | app functionality | question text sent to the AI provider, not stored |

  Data is encrypted in transit (HTTPS). Users can request deletion (in-app
  and via the web). No data is sold or used for ads.

- **Generative AI:** answers can be reported in the app (flag icon under
  each answer); reports go to the `ai_reports` table.

## 5. Backend (only when Supabase is configured)

```bash
supabase functions deploy delete-account
# then run supabase/ai_reports.sql once in the SQL editor
```

## Later

- Play Billing (in-app subscriptions) to sell Pro inside the Android app.
- iOS / App Store: add the iOS platform, build on macOS (or a cloud Mac such
  as Codemagic), Apple developer account, App Privacy labels.


## Paid plans and the store app (decided with the owner)

Google Play only lets an app sell digital subscriptions through Google's own
billing, and outside the US/EEA programs it forbids leading users to another
way to pay. So the store app **never sells, prices or links to a payment**; the
website sells, and the store app reads the account's plan from the server, so
a subscription bought on the website works there once the same account signs
in.

- While the app is in beta (`BETA_ALL_ACCESS` unset or true) the store app is
  open like the web app.
- When the beta ends, build **both** workflows with
  `--dart-define=BETA_ALL_ACCESS=false` (deploy-web.yml already has it;
  **add it to android.yml**). The store build then (`AppEnv.storeFreeMode`):
  applies the free plan's limits, takes the plan from the server, shows a
  plain note ("Some features are part of the Pro plan…") instead of plans,
  prices, coupons, trial, manage-subscription or an upgrade card, and the
  locked/limit sheets say what Pro lifts without a button to plans.
- Do **not** put prices, a payment link, "subscribe on our website" or
  "write to us to upgrade" anywhere in the store app or in the Play listing.
  The website, e-mail, social media and ads may say all of it.
- A support link (social account, e-mail) is fine on the Support page, worded
  as help, never next to a locked feature.
- `test/store_free_mode_test.dart` checks this and runs in CI with the store
  build settings.
