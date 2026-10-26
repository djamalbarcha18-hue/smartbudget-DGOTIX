# Continue with Google (hidden)

**Status: built, hidden.** The «Continue with Google» button on the sign-in
and sign-up pages appears only in builds made with
`--dart-define=GOOGLE_SIGN_IN=true`. Nothing else changes while it is off.

How it works: the button opens Google's own page (in the browser on Android,
in the same tab on the web). Google sends the user back to the app, and
Supabase finishes the sign-in. A new Google user gets an account; someone who
already has an account with the same e-mail address gets the two linked by
Supabase.

Sign in with Apple is not built: it needs a paid Apple Developer account, and
it becomes required only when the app ships on the App Store.

## Turning it on (the owner, once)

Everything below is free. Keep the client **secret** to yourself: it goes in
the Supabase dashboard only, never in the app, the repository or a chat.

1. **Google Cloud Console** (console.cloud.google.com), APIs & Services:
   - OAuth consent screen: app name SmartBudget, support e-mail, the site
     https://smartbudget.dgotix.com and its privacy policy page.
   - Credentials > Create credentials > OAuth client ID > **Web application**.
     Authorized redirect URI:
     `https://fconhnyognxcpvmwobus.supabase.co/auth/v1/callback`
   - Copy the client ID and the client secret.
2. **Supabase dashboard** > Authentication > Sign In / Providers > **Google**:
   turn it on, paste the client ID and secret, save.
3. Supabase > Authentication > **URL Configuration** > Redirect URLs, add:
   - `https://smartbudget.dgotix.com/`
   - `com.dgotix.smartbudget://login-callback` (the Android app)
4. Build with the flag: add `--dart-define=GOOGLE_SIGN_IN=true` to `DEFINES`
   in `.github/workflows/deploy-web.yml` and `.github/workflows/android.yml`.

## Files

- `lib/core/env/app_env.dart`: `AppEnv.googleSignIn` (the flag).
- `lib/features/auth/data/supabase_auth_repository.dart`: `signInWithGoogle`
  and the return addresses.
- `lib/features/auth/presentation/widgets/google_sign_in_button.dart`: the
  «or» line and the button.
- `android/app/src/main/AndroidManifest.xml`: the
  `com.dgotix.smartbudget://login-callback` link back into the app.
- `test/google_sign_in_test.dart`.
