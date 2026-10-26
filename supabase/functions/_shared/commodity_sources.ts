// Free commodity price sources for the market proxy. Pure helpers (URLs,
// parsers, mapping onto the app's codes) so they can be tested without the
// network.
//
// - IMF Primary Commodity Price System (PCPS): keyless, monthly averages of
//   benchmark prices, updated in the first week of each month. SDMX 3.0 API:
//   GET https://api.imf.org/external/sdmx/3.0/data/dataflow/IMF.RES/PCPS/+/
//       G001.<INDICATOR>[+<INDICATOR>…].USD.M?lastNObservations=2
//   Accept: application/vnd.sdmx.data+json;version=2.0.0
//   Observations come back as strings ("246.85180245").
// - U.S. EIA Open Data v2: daily Brent / WTI / Henry Hub spot prices with a
//   free key (EIA_API_KEY). Without a key EIA answers 403 API_KEY_MISSING, and
//   energy falls back to the IMF monthly averages.

export type Frequency = "monthly" | "daily";

export type Quote = {
  code: string;
  unit: string;
  benchmark?: string;
  region?: string;
  priceUsd?: number;
  previousUsd?: number;
  /** "2026-09" for a monthly average, "2026-10-24" for a daily price. */
  period?: string;
  frequency?: Frequency;
  source: string;
  updatedAt: string;
  quality: "realtime" | "nearRealtime" | "delayed" | "indicative" | "unavailable";
};

export type Spec = { code: string; unit: string; benchmark?: string; region?: string };

/** An IMF series behind one of the app's codes. [scale] turns the IMF unit
 *  into the one shown (US cents per pound → US dollars per pound). */
type ImfSeries = { indicator: string; unit: string; benchmark: string; region?: string; scale?: number };

export const IMF_SERIES: Record<string, ImfSeries> = {
  // Agriculture
  WHEAT: { indicator: "PWHEAMT", unit: "USD/t", benchmark: "US HRW, FOB Gulf" },
  CORN: { indicator: "PMAIZMT", unit: "USD/t", benchmark: "US No.2 Yellow, FOB Gulf" },
  RICE: { indicator: "PRICENPQ", unit: "USD/t", benchmark: "Thai 5% broken" },
  SOYB: { indicator: "PSOYB", unit: "USD/t", benchmark: "US soybeans" },
  SUGAR: { indicator: "PSUGAISA", unit: "USD/lb", benchmark: "No. 11, World", scale: 0.01 },
  COFFEE: { indicator: "PCOFFOTM", unit: "USD/lb", benchmark: "Other Mild Arabica", scale: 0.01 },
  COCOA: { indicator: "PCOCO", unit: "USD/t", benchmark: "Cocoa beans" },
  PALMOIL: { indicator: "PPOIL", unit: "USD/t", benchmark: "Palm oil" },
  // Iron ore (the IMF has no steel prices)
  IORE62: { indicator: "PIORECR", unit: "USD/t", benchmark: "62% Fe fines", region: "CFR China" },
  // Base metals
  XCU: { indicator: "PCOPP", unit: "USD/t", benchmark: "Copper" },
  ALU: { indicator: "PALUM", unit: "USD/t", benchmark: "Aluminum" },
  ZNC: { indicator: "PZINC", unit: "USD/t", benchmark: "Zinc" },
  NIK: { indicator: "PNICK", unit: "USD/t", benchmark: "Nickel" },
  LED: { indicator: "PLEAD", unit: "USD/t", benchmark: "Lead" },
  TIN: { indicator: "PTIN", unit: "USD/t", benchmark: "Tin" },
  COB: { indicator: "PCOBA", unit: "USD/t", benchmark: "Cobalt" },
  // Energy (monthly, when there is no EIA key)
  BRENT: { indicator: "POILBRE", unit: "USD/bbl", benchmark: "Brent" },
  WTI: { indicator: "POILWTI", unit: "USD/bbl", benchmark: "WTI" },
  NGAS: { indicator: "PNGASUS", unit: "USD/MMBtu", benchmark: "Henry Hub" },
};

export const IMF_ACCEPT = "application/vnd.sdmx.data+json;version=2.0.0";

export function imfUrl(codes: string[]): string | null {
  const indicators = codes.map((c) => IMF_SERIES[c]?.indicator).filter((i): i is string => !!i);
  if (indicators.length === 0) return null;
  return "https://api.imf.org/external/sdmx/3.0/data/dataflow/IMF.RES/PCPS/+/" +
    `G001.${[...new Set(indicators)].join("+")}.USD.M?lastNObservations=2`;
}

type Point = { period?: string; value: number; previous?: number };

function num(v: unknown): number | undefined {
  const n = typeof v === "number" ? v : typeof v === "string" ? Number(v) : NaN;
  return Number.isFinite(n) ? n : undefined;
}

/** A TIME_PERIOD value as "2026-09" (or whatever the source names it). */
function periodOf(v: unknown): string | undefined {
  if (!v || typeof v !== "object") return undefined;
  const o = v as Record<string, unknown>;
  for (const k of ["value", "id", "name", "start"]) {
    const s = o[k];
    if (typeof s === "string" && s) {
      // "2026-09", "2026-M09" or a start date "2026-09-01T00:00:00".
      const m = s.match(/^(\d{4})-?M?(\d{2})/);
      return m ? `${m[1]}-${m[2]}` : s;
    }
  }
  return undefined;
}

/** Latest and previous monthly value of each indicator in an SDMX-JSON 2.0
 *  answer. Series keys are positions ("0:3:0:0") into the series dimensions;
 *  observations are keyed by position in the TIME_PERIOD values. */
export function parseImf(json: unknown): Map<string, Point> {
  const out = new Map<string, Point>();
  const data = (json as { data?: Record<string, unknown> })?.data;
  const structure = (data?.structures as Array<Record<string, unknown>> | undefined)?.[0];
  const dims = (structure?.dimensions as Record<string, unknown> | undefined);
  const seriesDims = (dims?.series as Array<{ id: string; values: Array<{ id: string }> }> | undefined) ?? [];
  const timeValues = ((dims?.observation as Array<{ values: unknown[] }> | undefined)?.[0]?.values) ?? [];
  const indPos = seriesDims.findIndex((d) => d.id === "INDICATOR");
  const trPos = seriesDims.findIndex((d) => d.id === "DATA_TRANSFORMATION");
  const series = ((data?.dataSets as Array<{ series?: Record<string, unknown> }> | undefined)?.[0]?.series) ?? {};
  if (indPos < 0) return out;
  for (const [key, s] of Object.entries(series)) {
    const idx = key.split(":").map(Number);
    if (trPos >= 0 && seriesDims[trPos].values[idx[trPos]]?.id !== "USD") continue;
    const indicator = seriesDims[indPos].values[idx[indPos]]?.id;
    if (!indicator) continue;
    const obs = Object.entries((s as { observations?: Record<string, unknown[]> }).observations ?? {})
      .map(([k, v]) => ({ t: Number(k), value: num(v?.[0]) }))
      .filter((o): o is { t: number; value: number } => o.value !== undefined)
      .sort((a, b) => {
        const pa = periodOf(timeValues[a.t]) ?? String(a.t).padStart(6, "0");
        const pb = periodOf(timeValues[b.t]) ?? String(b.t).padStart(6, "0");
        return pa < pb ? -1 : pa > pb ? 1 : 0;
      });
    const last = obs.at(-1);
    if (!last) continue;
    out.set(indicator, {
      period: periodOf(timeValues[last.t]),
      value: last.value,
      previous: obs.length > 1 ? obs[obs.length - 2].value : undefined,
    });
  }
  return out;
}

/** The app's quotes from IMF points; codes without one stay unavailable. */
export function imfQuotes(specs: Spec[], points: Map<string, Point>, now: string): Quote[] {
  return specs.map((s) => {
    const m = IMF_SERIES[s.code];
    const p = m ? points.get(m.indicator) : undefined;
    if (!m || !p) return unavailableQuote(s, now);
    const k = m.scale ?? 1;
    return {
      code: s.code,
      unit: m.unit,
      benchmark: m.benchmark,
      region: m.region ?? s.region,
      priceUsd: round(p.value * k),
      previousUsd: p.previous === undefined ? undefined : round(p.previous * k),
      period: p.period,
      frequency: "monthly",
      source: "IMF",
      updatedAt: now,
      quality: "indicative",
    };
  });
}

// ---- EIA (daily, needs a free key) ----

export const EIA_SERIES: Record<string, { route: string; series: string; unit: string; benchmark: string }> = {
  BRENT: { route: "petroleum/pri/spt", series: "RBRTE", unit: "USD/bbl", benchmark: "Europe Brent Spot" },
  WTI: { route: "petroleum/pri/spt", series: "RWTC", unit: "USD/bbl", benchmark: "WTI Cushing Spot" },
  NGAS: { route: "natural-gas/pri/fut", series: "RNGWHHD", unit: "USD/MMBtu", benchmark: "Henry Hub Spot" },
};

/** One request per route, the last ~10 daily values of its series. */
export function eiaUrls(codes: string[], key: string): string[] {
  const byRoute = new Map<string, string[]>();
  for (const c of codes) {
    const m = EIA_SERIES[c];
    if (!m) continue;
    byRoute.set(m.route, [...(byRoute.get(m.route) ?? []), m.series]);
  }
  return [...byRoute.entries()].map(([route, series]) => {
    const p = new URLSearchParams({
      api_key: key,
      frequency: "daily",
      "data[0]": "value",
      "sort[0][column]": "period",
      "sort[0][direction]": "desc",
      length: String(10 * series.length),
    });
    for (const s of series) p.append("facets[series][]", s);
    return `https://api.eia.gov/v2/${route}/data/?${p}`;
  });
}

/** Latest and previous day of each series in an EIA v2 answer
 *  ({ response: { data: [{ period, series, value }] } }). */
export function parseEia(json: unknown): Map<string, Point> {
  const out = new Map<string, Point>();
  const rows = (json as { response?: { data?: unknown[] } })?.response?.data;
  if (!Array.isArray(rows)) return out;
  const bySeries = new Map<string, Array<{ period: string; value: number }>>();
  for (const r of rows as Array<Record<string, unknown>>) {
    const series = typeof r.series === "string" ? r.series : undefined;
    const period = typeof r.period === "string" ? r.period : undefined;
    const value = num(r.value);
    if (!series || !period || value === undefined) continue;
    bySeries.set(series, [...(bySeries.get(series) ?? []), { period, value }]);
  }
  for (const [series, list] of bySeries) {
    list.sort((a, b) => (a.period < b.period ? 1 : a.period > b.period ? -1 : 0));
    out.set(series, { period: list[0].period, value: list[0].value, previous: list[1]?.value });
  }
  return out;
}

export function eiaQuotes(specs: Spec[], points: Map<string, Point>, now: string): Quote[] {
  return specs.map((s) => {
    const m = EIA_SERIES[s.code];
    const p = m ? points.get(m.series) : undefined;
    if (!m || !p) return unavailableQuote(s, now);
    return {
      code: s.code,
      unit: m.unit,
      benchmark: m.benchmark,
      region: s.region,
      priceUsd: p.value,
      previousUsd: p.previous,
      period: p.period,
      frequency: "daily",
      source: "U.S. EIA",
      updatedAt: now,
      quality: "delayed",
    };
  });
}

export function unavailableQuote(s: Spec, now: string, source = "requires data source"): Quote {
  return {
    code: s.code,
    unit: s.unit,
    benchmark: s.benchmark,
    region: s.region,
    source: s.benchmark ?? source,
    updatedAt: now,
    quality: "unavailable",
  };
}

/** Per spec, the first quote with a price among [lists] (in order), else the
 *  unavailable one. */
export function preferPriced(specs: Spec[], lists: Quote[][], now: string): Quote[] {
  return specs.map((s) =>
    lists.map((l) => l.find((q) => q.code === s.code && q.priceUsd !== undefined))
      .find((q) => q !== undefined) ?? unavailableQuote(s, now)
  );
}

function round(v: number): number {
  return Math.round(v * 10000) / 10000;
}
