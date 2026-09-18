# Receipt Scanner — architecture & setup

Scan a receipt, extract structured data with AI, and pre-fill the **Add
expense** form. Hybrid by design:

| Path | Engine | Where it runs | Cost |
|------|--------|---------------|------|
| **Online (primary)** | Gemini Flash via a Supabase Edge Function | any platform (web + mobile) | free within each user's own Gemini quota (BYOK) |
| **Offline (fallback)** | Google ML Kit Text Recognition | Android / iOS only | free, on-device |

> ML Kit has **no web implementation**, so on Flutter Web only the online path
> is available. The client selects the engine behind a `ReceiptOcrEngine`
> interface, so wiring ML Kit for the mobile targets later needs no UI changes.

## BYOK (Bring Your Own Key)

Each user pastes their own Gemini API key once, in **Settings → Receipt
scanning**. The key is:

1. sent to the `save-gemini-key` Edge Function over HTTPS with the user's
   session JWT,
2. encrypted with **AES-256-GCM** inside the function (`KEY_ENCRYPTION_SECRET`),
3. stored as **ciphertext only** in `user_ai_keys` (RLS blocks all client
   access; only the service role, used by the functions, can read it),
4. decrypted server-side per request by `receipt-scan` to call Gemini.

The plaintext key is never returned to any client and never logged. The client
can only learn *whether* a key is set.

## One-time setup (project owner)

```bash
# 1. Create the table + RLS
psql "$SUPABASE_DB_URL" -f supabase/receipt_scanner.sql
#    (or paste supabase/receipt_scanner.sql into the Supabase SQL editor)

# 2. Set the encryption secret (32 random bytes, base64)
supabase secrets set KEY_ENCRYPTION_SECRET="$(openssl rand -base64 32)"
#    Optional: pin a model / restrict CORS
supabase secrets set GEMINI_MODEL=gemini-2.0-flash
supabase secrets set ALLOWED_ORIGIN=https://<your-github-pages-origin>

# 3. Deploy the functions
supabase functions deploy save-gemini-key
supabase functions deploy receipt-scan
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected
into Edge Functions automatically — do not set them by hand.

## Per-user setup (end user)

1. Get a free key at <https://aistudio.google.com/apikey>.
2. Paste it in **Settings → Receipt scanning** and press Save.
3. Open **Expenses → Scan receipt**, take/choose a photo, review, and save.

## API contract

`POST /functions/v1/receipt-scan` (JWT required)

```jsonc
// request
{ "imageBase64": "<base64 without data: prefix>", "mimeType": "image/jpeg" }

// success
{ "ok": true, "merchant_name": "…", "date": "2026-03-10",
  "total_amount": 42.5, "currency": "USD", "category": "المطاعم",
  "confidence": 0.92 }

// unreadable image (never an invented number)
{ "ok": false, "reason": "unreadable" | "no_total" }

// errors
{ "error": "no_key" | "invalid_key" | "rate_limited" | "provider_error" | … }
```

`POST /functions/v1/save-gemini-key` (JWT required), action-based:
`{ "action": "status" }` → `{ hasKey }`, `{ "action": "save", "apiKey": "…" }`
stores it, `{ "action": "delete" }` removes it.
