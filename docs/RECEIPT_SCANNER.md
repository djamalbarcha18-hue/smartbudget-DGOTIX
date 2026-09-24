# Receipt Scanner — architecture & setup

Scan a receipt, extract structured data with AI, and pre-fill the **Add
expense** form. Hybrid by design:

| Path | Engine | Where it runs | Cost |
|------|--------|---------------|------|
| **Online (primary)** | Gemini Flash via a Supabase Edge Function, with DGOTIX's server key | any platform (web + mobile) | included in the plan's cloud-OCR quota (3 lifetime / 15 / 100 per month) |
| **Offline (fallback)** | Google ML Kit Text Recognition | Android / iOS only | free, on-device |

> ML Kit has **no web implementation**, so on Flutter Web only the online path
> is available. The client selects the engine behind a `ReceiptOcrEngine`
> interface, so wiring ML Kit for the mobile targets later needs no UI changes.

## DGOTIX is the only AI provider

Users never bring their own key. The `receipt-scan` function calls Gemini with
DGOTIX's server key (`GEMINI_API_KEY`, an Edge Function secret) and meters every
successful scan against the plan's cloud-OCR quota (`OCR_QUOTA` in
`supabase/functions/_shared/quota.ts`). When the quota is reached the only call
to action is **Upgrade**. The key never reaches the frontend and is never
logged. Without a server key the function answers `ocr_unavailable` and the app
says the cloud scan is unavailable; core features are unaffected.

## One-time setup (project owner)

```bash
# 1. Drop the retired personal-key table (safe to run more than once)
psql "$SUPABASE_DB_URL" -f supabase/receipt_scanner.sql
#    (or paste supabase/receipt_scanner.sql into the Supabase SQL editor)

# 2. Set the server key (and optionally pin a model / restrict CORS)
supabase secrets set GEMINI_API_KEY=<your Gemini key>
supabase secrets set GEMINI_MODEL=gemini-flash-latest
supabase secrets set ALLOWED_ORIGIN=https://<your-github-pages-origin>

# 3. Deploy the function (and remove the retired one if it was deployed)
supabase functions deploy receipt-scan
supabase functions delete save-gemini-key
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected
into Edge Functions automatically — do not set them by hand.

## End user

Open **Expenses → Scan receipt**, take/choose a photo, review, and save. No
setup is needed.

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
{ "error": "ocr_unavailable" | "quota_exceeded" | "rate_limited" | "provider_error" | … }
```
