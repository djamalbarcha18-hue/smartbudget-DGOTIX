# Market Intelligence — data backend (owner guide)

Prices for **industrial metals, steel & iron, energy, and agriculture** come
through a small **proxy** (the `market-proxy` Supabase Edge Function). It
holds any provider key server-side; no key ever ships in the app.

Already live for free in the app itself: **Exchange Rates** (open.er-api.com),
**Crypto** (CoinGecko), **Precious Metals** and **platinum / palladium**
(gold-api.com).

## Free sources (default: `MARKET_PROVIDER=free`)

| Category | Source | What the app shows |
|---|---|---|
| Agriculture (wheat, corn, rice, soybeans, sugar, coffee, cocoa, palm oil) | IMF Primary Commodity Price System, keyless | the **monthly average**, labelled with its month, and the change from the month before |
| Iron ore 62% Fe | IMF PCPS | monthly average |
| Copper, aluminum, zinc, nickel, lead, tin, cobalt | IMF PCPS | monthly average |
| Brent, WTI, Henry Hub gas | **U.S. EIA** (daily) when `EIA_API_KEY` is set; otherwise IMF monthly | the day's price, or the month's average |
| Steel (HRC, rebar, billet, scrap), iron ore 58% | none free | "unavailable", grouped on one card |

The IMF updates PCPS in the first full week of each month; the proxy keeps an
answer for an hour (5 minutes after a failure). Sugar and coffee, quoted by
the IMF in US cents per pound, are shown in US dollars per pound.

**Daily oil and gas (optional, free):** register at
https://www.eia.gov/opendata/register.php — the key arrives by e-mail — then
add it yourself in the Supabase dashboard (Edge Functions > Secrets) as
`EIA_API_KEY`. Never paste it in the app, the repository or a chat.

The app learns the proxy's address at build time
(`MARKET_API_URL=<SUPABASE_URL>/functions/v1/market-proxy`, set by the web and
Android workflows). Without it, these tabs show "unavailable" — never a made-up
number.

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
supabase secrets set ALLOWED_ORIGIN=https://smartbudget.dgotix.com
```

`MARKET_PROVIDER=free` (the default) needs no key; `none` returns every
commodity as `quality:"unavailable"`. Add an adapter in
`supabase/functions/market-proxy/index.ts` for the provider you pick.

## Response contract (what the app expects)

```json
{ "category": "industrialMetals",
  "quotes": [
    { "code": "XCU", "priceUsd": 9500.0, "unit": "USD/t",
      "benchmark": "LME", "source": "MetalpriceAPI",
      "updatedAt": "2026-01-01T00:00:00Z", "quality": "delayed",
      "period": "2026-09", "frequency": "monthly", "previousUsd": 9400.0 }
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
