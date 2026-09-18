// SmartBudget — Market Intelligence proxy (Supabase Edge Function, Deno).
//
// PURPOSE
//   Serve normalized commodity/metal quotes to the Flutter web client WITHOUT
//   ever exposing a provider API key to the frontend. The OWNER (not end users)
//   selects the data provider and supplies its key through server-side
//   environment variables. The client only knows this function's public URL.
//
// SECURITY
//   - API keys are read from Deno.env — never returned to the client, never
//     committed. Set them with:  supabase secrets set METALPRICEAPI_KEY=...
//   - CORS is restricted to the configured site origin (ALLOWED_ORIGIN).
//
// CONTRACT
//   GET ?category=<industrialMetals|steelIron|energy|agriculture|preciousMetals>
//   ->  { "category": "...", "quotes": [ {
//           code, priceUsd, previousUsd?, unit, benchmark?, region?,
//           source, updatedAt, quality } ] }
//   A code with no reliable price is returned with quality:"unavailable" and no
//   priceUsd — the proxy NEVER invents a number.
//
// PROVIDER CHOICE (owner-controlled)
//   MARKET_PROVIDER selects the adapter. "none" (default) returns everything as
//   unavailable, so the function is safe to deploy immediately with no keys.
//   Add an adapter below and set MARKET_PROVIDER + its key when you choose one.

const ALLOWED_ORIGIN = Deno.env.get("ALLOWED_ORIGIN") ?? "*";
const PROVIDER = (Deno.env.get("MARKET_PROVIDER") ?? "none").toLowerCase();

// Which codes belong to each category, and the symbol a provider expects.
// Mirrors the Flutter CommodityConfig; extend here + there together.
const CATALOG: Record<string, Array<{ code: string; unit: string; benchmark?: string; region?: string; symbol?: string }>> = {
  industrialMetals: [
    { code: "XCU", unit: "USD/t", benchmark: "LME", symbol: "LME-XCU" },
    { code: "ALU", unit: "USD/t", benchmark: "LME", symbol: "LME-ALU" },
    { code: "ZNC", unit: "USD/t", benchmark: "LME", symbol: "LME-ZNC" },
    { code: "NIK", unit: "USD/t", benchmark: "LME", symbol: "LME-NIK" },
    { code: "LED", unit: "USD/t", benchmark: "LME", symbol: "LME-LED" },
    { code: "TIN", unit: "USD/t", benchmark: "LME", symbol: "LME-TIN" },
    { code: "COB", unit: "USD/t", benchmark: "LME", symbol: "LME-COB" },
  ],
  steelIron: [
    { code: "IORE62", unit: "USD/dmt", benchmark: "Platts 62% Fe", region: "CFR China" },
    { code: "IORE58", unit: "USD/dmt", benchmark: "Platts 58% Fe", region: "CFR China" },
    { code: "HRC", unit: "USD/t", benchmark: "HRC" },
    { code: "REBAR", unit: "USD/t", benchmark: "Rebar" },
    { code: "BILLET", unit: "USD/t", benchmark: "Billet" },
    { code: "SCRAP", unit: "USD/t", benchmark: "Scrap" },
  ],
  energy: [
    { code: "BRENT", unit: "USD/bbl", benchmark: "ICE Brent", symbol: "BRENTOIL" },
    { code: "WTI", unit: "USD/bbl", benchmark: "NYMEX WTI", symbol: "WTIOIL" },
    { code: "NGAS", unit: "USD/MMBtu", benchmark: "Henry Hub", symbol: "NG" },
  ],
  agriculture: [
    { code: "WHEAT", unit: "USd/bu", benchmark: "CBOT", symbol: "WHEAT" },
    { code: "CORN", unit: "USd/bu", benchmark: "CBOT", symbol: "CORN" },
    { code: "SOYB", unit: "USd/bu", benchmark: "CBOT", symbol: "SOYBEAN" },
    { code: "SUGAR", unit: "USd/lb", benchmark: "ICE", symbol: "SUGAR" },
    { code: "COFFEE", unit: "USd/lb", benchmark: "ICE", symbol: "COFFEE" },
    { code: "COCOA", unit: "USD/t", benchmark: "ICE", symbol: "COCOA" },
  ],
  preciousMetals: [
    { code: "XAU", unit: "USD/oz", symbol: "XAU" },
    { code: "XAG", unit: "USD/oz", symbol: "XAG" },
    { code: "XPT", unit: "USD/oz", symbol: "XPT" },
    { code: "XPD", unit: "USD/oz", symbol: "XPD" },
  ],
};

type Spec = { code: string; unit: string; benchmark?: string; region?: string; symbol?: string };
type Quote = {
  code: string;
  unit: string;
  benchmark?: string;
  region?: string;
  priceUsd?: number;
  previousUsd?: number;
  source: string;
  updatedAt: string;
  quality: "realtime" | "nearRealtime" | "delayed" | "indicative" | "unavailable";
};

// A provider adapter maps specs -> quotes. Add your chosen provider here.
type Adapter = (category: string, specs: Spec[]) => Promise<Quote[]>;

function unavailable(specs: Spec[], source = "requires data source"): Quote[] {
  const now = new Date().toISOString();
  return specs.map((s) => ({
    code: s.code,
    unit: s.unit,
    benchmark: s.benchmark,
    region: s.region,
    source: s.benchmark ?? source,
    updatedAt: now,
    quality: "unavailable",
  }));
}

// EXAMPLE adapter (metalpriceapi.com). Inert unless METALPRICEAPI_KEY is set and
// MARKET_PROVIDER=metalpriceapi. Verify the plan's symbols/units/redistribution
// rights before enabling. Anything the provider doesn't cover stays unavailable.
const metalPriceApi: Adapter = async (_category, specs) => {
  const key = Deno.env.get("METALPRICEAPI_KEY");
  if (!key) return unavailable(specs, "metalpriceapi (no key)");
  const symbols = specs.map((s) => s.symbol ?? s.code).join(",");
  try {
    const res = await fetch(
      `https://api.metalpriceapi.com/v1/latest?api_key=${key}&base=USD&currencies=${symbols}`,
    );
    if (!res.ok) return unavailable(specs, "metalpriceapi (http)");
    const json = await res.json();
    const rates = (json?.rates ?? {}) as Record<string, number>;
    const now = new Date().toISOString();
    return specs.map((s) => {
      const sym = s.symbol ?? s.code;
      const perUsd = rates[sym];
      // metalpriceapi returns units-per-USD; invert to USD-per-unit.
      const priceUsd = typeof perUsd === "number" && perUsd > 0 ? 1 / perUsd : undefined;
      return {
        code: s.code,
        unit: s.unit,
        benchmark: s.benchmark,
        region: s.region,
        priceUsd,
        source: "MetalpriceAPI",
        updatedAt: now,
        quality: priceUsd ? "delayed" : "unavailable",
      } as Quote;
    });
  } catch {
    return unavailable(specs, "metalpriceapi (error)");
  }
};

const ADAPTERS: Record<string, Adapter> = {
  none: (_c, specs) => Promise.resolve(unavailable(specs)),
  metalpriceapi: metalPriceApi,
  // Add more owner-chosen adapters here (e.g. twelvedata, tradingeconomics…).
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
  const category = url.searchParams.get("category") ?? "";
  const specs = CATALOG[category];
  if (!specs) {
    return new Response(JSON.stringify({ error: "unknown category" }), {
      status: 400,
      headers: cors(),
    });
  }

  const adapter = ADAPTERS[PROVIDER] ?? ADAPTERS.none;
  const quotes = await adapter(category, specs);
  return new Response(JSON.stringify({ category, quotes }), { headers: cors() });
});
