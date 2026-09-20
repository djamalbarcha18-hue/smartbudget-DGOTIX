// SmartBudget — Parallel-market FX proxy (Supabase Edge Function, Deno).
//
// PURPOSE
//   Serve normalized parallel ("street") FX quotes per country to the Flutter
//   web client WITHOUT exposing any provider key to the frontend. The OWNER
//   (not end users) chooses each country's data source and supplies any key via
//   server-side environment variables. The client only knows this function's
//   public URL (PARALLEL_API_URL).
//
// SECURITY
//   - Keys are read from Deno.env — never returned to the client, never committed.
//   - CORS is restricted to the configured site origin (ALLOWED_ORIGIN).
//
// CONTRACT
//   GET ?country=<iso2>
//   -> { "country": "dz", "quotes": [ { currency, base, buy?, sell?, source,
//        updatedAt } ] }
//   A pair with neither buy nor sell is omitted — the proxy NEVER invents a rate.
//
// PROVIDER CHOICE (owner-controlled)
//   Wire each country in ADAPTERS below to a real source you trust (a public
//   API, or a scraper you host). With nothing wired, every country returns an
//   empty quote list, so the client shows "unavailable" and the in-app manual
//   entry remains the fallback. Deploy is therefore safe with zero config.

const ALLOWED_ORIGIN = Deno.env.get("ALLOWED_ORIGIN") ?? "*";

type Quote = {
  currency: string;
  base: string;
  buy?: number;
  sell?: number;
  source: string;
  updatedAt: string;
};

// The base currency per country (matches the Flutter MarketConfig).
const BASES: Record<string, string> = {
  dz: "DZD",
  lb: "LBP",
  ng: "NGN",
  ar: "ARS",
};

// A country adapter returns real parallel quotes, or [] when it has no source.
type Adapter = (country: string) => Promise<Quote[]>;

function num(v: unknown): number | undefined {
  const n = typeof v === "string" ? parseFloat(v) : (v as number);
  return typeof n === "number" && isFinite(n) && n > 0 ? n : undefined;
}

// EXAMPLE adapter shape (kept inert). To enable a country, fetch its source,
// map to { currency, base, buy?, sell?, ... } and drop anything with no value.
//
//   const nigeria: Adapter = async () => {
//     const key = Deno.env.get("NG_PARALLEL_KEY");
//     const res = await fetch(`https://your-source/...?apikey=${key}`);
//     if (!res.ok) return [];
//     const j = await res.json();
//     const buy = num(j.buy), sell = num(j.sell);
//     if (buy === undefined && sell === undefined) return [];
//     return [{ currency: "USD", base: "NGN", buy, sell,
//               source: "your-source", updatedAt: new Date().toISOString() }];
//   };

const ADAPTERS: Record<string, Adapter> = {
  // Wire real sources here, e.g.  ng: nigeria,  lb: lebanon,  dz: algeria
};

function cors(): HeadersInit {
  return {
    "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, content-type",
    "Content-Type": "application/json",
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors() });

  const url = new URL(req.url);
  const country = (url.searchParams.get("country") ?? "").toLowerCase();
  if (!country || !(country in BASES)) {
    return new Response(JSON.stringify({ error: "unknown country" }), {
      status: 400,
      headers: cors(),
    });
  }

  const adapter = ADAPTERS[country];
  let quotes: Quote[] = [];
  if (adapter) {
    try {
      quotes = await adapter(country);
    } catch {
      quotes = []; // never fabricate on error
    }
  }
  // Drop any malformed/empty quote defensively.
  quotes = quotes.filter((q) => num(q.buy) !== undefined || num(q.sell) !== undefined);

  return new Response(JSON.stringify({ country, quotes }), { headers: cors() });
});
