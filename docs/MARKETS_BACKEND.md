# Market Intelligence — data backend (owner guide)

Live prices for **industrial metals, steel & iron, energy, and agriculture**
require a paid/licensed data provider. To keep the frontend key-free, those
categories are served through a small **proxy** (a Supabase Edge Function) that
**you, the owner**, deploy and configure. End users never choose a provider and
no API key ever ships in the Flutter app.

Already live for free (no backend needed): **Exchange Rates** (open.er-api.com),
**Crypto** (CoinGecko), **Precious Metals** spot (gold-api.com).

## How it fits together

```
Flutter web (GitHub Pages)  ──GET ?category=…──▶  market-proxy (Edge Function)
   knows only MARKET_API_URL                         holds the provider key
   (a public, non-secret URL)                         picks the provider (you)
                                                       ▼
                                              provider API (metals/energy/…)
```

- The app reads `MARKET_API_URL` (a plain URL) at build time via
  `--dart-define=MARKET_API_URL=https://<project>.functions.supabase.co/market-proxy`.
- If it is not set, the commodity tabs show **"unavailable"** — never fake data.

## Deploy the proxy

```bash
supabase functions deploy market-proxy
# choose your provider + key (server-side only):
supabase secrets set MARKET_PROVIDER=metalpriceapi
supabase secrets set METALPRICEAPI_KEY=xxxxxxxx
supabase secrets set ALLOWED_ORIGIN=https://djamalbarcha18-hue.github.io
```

`MARKET_PROVIDER=none` (the default) is safe to deploy with no key — every
commodity returns `quality:"unavailable"`. Add an adapter in
`supabase/functions/market-proxy/index.ts` for the provider you pick.

## Response contract (what the app expects)

```json
{ "category": "industrialMetals",
  "quotes": [
    { "code": "XCU", "priceUsd": 9500.0, "unit": "USD/t",
      "benchmark": "LME", "source": "MetalpriceAPI",
      "updatedAt": "2026-01-01T00:00:00Z", "quality": "delayed" }
  ] }
```

Any code omitted, or returned without `priceUsd`, renders as "unavailable".

## Choosing a provider (you decide — do not purchase without deciding)

| Category | Free/keyless? | Typical providers (keyed/paid) | Licensing note |
|---|---|---|---|
| Precious metals | ✅ gold-api.com (delayed) | MetalpriceAPI, GoldAPI.io | display OK; attribution |
| Industrial (LME) | ❌ | MetalpriceAPI, Trading Economics | LME data is **licensed** — check redistribution rights |
| Steel & Iron | ❌ | Trading Economics, Fastmarkets, Platts | benchmark redistribution restricted |
| Energy (Brent/WTI/NG) | ❌ (keys) | Twelve Data, EIA (US), FMP | check commercial + delayed-display terms |
| Agriculture | ❌ | Twelve Data, FMP, Trading Economics | CBOT/ICE futures licensed |
| Historical / 24h·7d·30d·YTD·52w | ❌ | same, history tiers | needs stored series (add a DB table) |

Before subscribing to any commercial API, verify: price, request limits,
historical range, commercial-SaaS usage, redistribution & display rights,
regional restrictions, and attribution requirements.

## Historical charts (next step)

52-week high/low and change-over-time need a stored time series. Add a Postgres
table (e.g. `commodity_history(code, ts, price_usd, source)`), have the Edge
Function upsert each fetch, and expose `?category=…&history=1`. The
`CommodityQuote` model already carries the `change24h/7d/30d/YTD` and
`high52w/low52w` fields for when that source exists.
