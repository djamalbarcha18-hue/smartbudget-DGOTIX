# Continue with Google (hidden)

**Status: on.** The «Continue with Google» button on the sign-in and sign-up
pages appears in builds made with `--dart-define=GOOGLE_SIGN_IN=true`, which
deploy-web.yml and android.yml now pass. Steps 1–3 below must be done in
Google Cloud and Supabase, or the button opens an error page.

How it works: the button opens Google's own page (in the browser on Android,
in the same tab on the web). Google sends the user back to the app, and
Supabase finishes the sign-in. A new Google user gets an account; someone who
already has an account with the same e-mail address gets the two linked by
Supabase.

Sign in with Apple is not built: it needs a paid Apple Developer account, and
it becomes required only when the app ships on the App Store.

## The website: Google's own button (no Supabase address at Google)

With `--dart-define=GOOGLE_WEB_CLIENT_ID=<web client id>` (deploy-web.yml has
it; the id is public), the website shows Google's own button, served from this
site (`web/google_signin.html`, framed like the Turnstile check). Google
answers here with an ID token; the app hands it to Supabase
(`signInWithIdToken`) with a nonce whose SHA-256 Google wrote into the token.
Google never sends anyone to `<project>.supabase.co`, so once the redirect URI
is removed, the only authorised domain is `dgotix.com` and Google's brand
verification can show «SmartBudget» on the consent screen.

Google Cloud, on that web client:
- **Authorised JavaScript origins**: `https://smartbudget.dgotix.com`.
- Once the button works on the site: remove the redirect URI
  `https://fconhnyognxcpvmwobus.supabase.co/auth/v1/callback`, then remove
  that domain from Branding → Authorised domains.

Supabase › Google: the web client id in **Client IDs** (it is the token's
audience), with **Skip nonce checks** off.

The Android build has no Google button for now (`GOOGLE_SIGN_IN` is not set in
android.yml): its version is Google's native sign-in (Credential Manager), for
the Play Store build. It needs an Android OAuth client (package name + SHA-1 of
the signing key) and the same `signInWithIdToken`.

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
4. Build with the flag: `--dart-define=GOOGLE_SIGN_IN=true` in `DEFINES` in
   `.github/workflows/deploy-web.yml` and `.github/workflows/android.yml` (done).

## Files

- `lib/core/env/app_env.dart`: `AppEnv.googleSignIn` (the flag).
- `lib/features/auth/data/supabase_auth_repository.dart`: `signInWithGoogle`
  and the return addresses.
- `lib/features/auth/presentation/widgets/google_sign_in_button.dart`: the
  «or» line and the button.
- `android/app/src/main/AndroidManifest.xml`: the
  `com.dgotix.smartbudget://login-callback` link back into the app.
- `test/google_sign_in_test.dart`.
