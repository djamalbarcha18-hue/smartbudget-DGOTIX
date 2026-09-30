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
4. Store listing:
   - app icon 512×512: `assets/launcher/play_store_icon_512.png`
   - feature graphic 1024×500: `assets/launcher/play_feature_graphic.png`
   - at least 2 phone screenshots (Arabic and English)
   - short and full description, **support e-mail** (required)
5. Policy pages (public, no sign-in needed):
   - Privacy policy: `https://smartbudget.dgotix.com/#/privacy`
     (`?lang=en` for English)
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
| Financial info (budget data) | only with cloud backup | backup, app functionality | encrypted in transit, deletable |
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
