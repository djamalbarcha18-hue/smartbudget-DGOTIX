import {
  eiaQuotes,
  eiaUrls,
  imfQuotes,
  imfUrl,
  parseEia,
  parseImf,
  preferPriced,
  type Spec,
} from "./commodity_sources.ts";

function eq(a: unknown, b: unknown, what: string) {
  if (JSON.stringify(a) !== JSON.stringify(b)) {
    throw new Error(`${what}: ${JSON.stringify(a)} != ${JSON.stringify(b)}`);
  }
}

// The shape the IMF SDMX 3.0 API answered for
// G001.PWHEAMT+PSUGAISA.<all transformations>.M?lastNObservations=2
// (series dimensions COUNTRY, INDICATOR, DATA_TRANSFORMATION, FREQUENCY;
// observation values as strings; only the USD series are prices).
function imfAnswer(timeValue: (p: string) => Record<string, string>) {
  return {
    meta: {},
    data: {
      dataSets: [{
        structure: 0,
        action: "Replace",
        series: {
          "0:0:0:0": { attributes: [0, null, null], observations: { "0": ["166.09", null, 0], "1": ["172.38", null, 0] } },
          "0:0:3:0": { attributes: [0, null, null], observations: { "0": ["237.8554019809524", null, 0], "1": ["246.85180245", null, 0] } },
          "0:1:3:0": { attributes: [0, null, null], observations: { "0": ["16.2261904761905", null, 0], "1": ["15.5", null, 0] } },
          "0:1:1:0": { attributes: [0, null, null], observations: { "0": ["-8.46", null, 0], "1": ["-4.2", null, 0] } },
        },
      }],
      structures: [{
        dimensions: {
          series: [
            { id: "COUNTRY", keyPosition: 0, values: [{ id: "G001" }] },
            { id: "INDICATOR", keyPosition: 1, values: [{ id: "PWHEAMT" }, { id: "PSUGAISA" }] },
            {
              id: "DATA_TRANSFORMATION",
              keyPosition: 2,
              values: [{ id: "INDEX" }, { id: "INDEX_PCH" }, { id: "INDEX_PCHY" }, { id: "USD" }],
            },
            { id: "FREQUENCY", keyPosition: 3, values: [{ id: "M" }] },
          ],
          observation: [{ id: "TIME_PERIOD", keyPosition: 4, values: [timeValue("2026-08"), timeValue("2026-09")] }],
        },
      }],
    },
  };
}

const specs: Spec[] = [
  { code: "WHEAT", unit: "USD/t", benchmark: "Wheat" },
  { code: "SUGAR", unit: "USD/lb", benchmark: "Sugar" },
  { code: "HRC", unit: "USD/t", benchmark: "HRC" },
];

Deno.test("IMF: one request for every code it covers, none for steel", () => {
  eq(
    imfUrl(["WHEAT", "SUGAR", "HRC"]),
    "https://api.imf.org/external/sdmx/3.0/data/dataflow/IMF.RES/PCPS/+/G001.PWHEAMT+PSUGAISA.USD.M?lastNObservations=2",
    "url",
  );
  eq(imfUrl(["HRC", "REBAR"]), null, "nothing to ask");
});

Deno.test("IMF: the US-dollar series, latest month and the one before", () => {
  for (const shape of [(p: string) => ({ value: p }), (p: string) => ({ id: p }), (p: string) => ({ start: `${p}-01T00:00:00` })]) {
    const points = parseImf(imfAnswer(shape));
    eq(points.get("PWHEAMT"), { period: "2026-09", value: 246.85180245, previous: 237.8554019809524 }, "wheat");
    eq(points.get("PSUGAISA")?.value, 15.5, "sugar, not its percent change");
  }
});

Deno.test("IMF: quotes in the app's codes; cents per pound become dollars", () => {
  const q = imfQuotes(specs, parseImf(imfAnswer((p) => ({ value: p }))), "2026-10-26T00:00:00Z");
  eq(q[0].priceUsd, 246.8518, "wheat");
  eq(q[0].previousUsd, 237.8554, "wheat before");
  eq([q[0].period, q[0].frequency, q[0].quality, q[0].source], ["2026-09", "monthly", "indicative", "IMF"], "labels");
  eq([q[1].priceUsd, q[1].unit], [0.155, "USD/lb"], "sugar");
  eq([q[2].priceUsd, q[2].quality], [undefined, "unavailable"], "steel has no free source");
});

Deno.test("IMF: an empty or odd answer gives nothing, never a number", () => {
  eq(parseImf({}).size, 0, "empty");
  eq(parseImf({ data: { dataSets: [{ series: { "0:0:0:0": { observations: { "0": ["n/a"] } } } }] } }).size, 0, "odd");
});

const eiaAnswer = {
  response: {
    total: 6,
    frequency: "daily",
    data: [
      { period: "2026-10-23", series: "RBRTE", "series-description": "Europe Brent Spot Price FOB", value: "80.12", units: "$/BBL" },
      { period: "2026-10-24", series: "RBRTE", value: 81.5, units: "$/BBL" },
      { period: "2026-10-24", series: "RWTC", value: "77.9", units: "$/BBL" },
      { period: "2026-10-23", series: "RWTC", value: null, units: "$/BBL" },
    ],
  },
};

Deno.test("EIA: one request per route, the key in the query", () => {
  const urls = eiaUrls(["BRENT", "WTI", "NGAS", "WHEAT"], "k");
  eq(urls.length, 2, "petroleum and natural gas");
  const u = new URL(urls[0]);
  eq(u.pathname, "/v2/petroleum/pri/spt/data/", "route");
  eq(u.searchParams.getAll("facets[series][]"), ["RBRTE", "RWTC"], "series");
  eq([u.searchParams.get("api_key"), u.searchParams.get("frequency")], ["k", "daily"], "params");
  eq(new URL(urls[1]).searchParams.getAll("facets[series][]"), ["RNGWHHD"], "gas");
});

Deno.test("EIA: latest day per series, strings or numbers, gaps skipped", () => {
  const p = parseEia(eiaAnswer);
  eq(p.get("RBRTE"), { period: "2026-10-24", value: 81.5, previous: 80.12 }, "brent");
  eq(p.get("RWTC"), { period: "2026-10-24", value: 77.9, previous: undefined }, "wti");
  eq(parseEia({ error: { code: "API_KEY_MISSING" } }).size, 0, "no key");
});

Deno.test("energy: the EIA's daily price first, the IMF's month when it has none", () => {
  const energy: Spec[] = [
    { code: "BRENT", unit: "USD/bbl" },
    { code: "NGAS", unit: "USD/MMBtu" },
  ];
  const now = "2026-10-26T00:00:00Z";
  const daily = eiaQuotes(energy, parseEia(eiaAnswer), now);
  const monthly = imfQuotes(energy, new Map([["POILBRE", { period: "2026-09", value: 70 }], ["PNGASUS", { period: "2026-09", value: 3.1 }]]), now);
  const q = preferPriced(energy, [daily, monthly], now);
  eq([q[0].priceUsd, q[0].frequency, q[0].source], [81.5, "daily", "U.S. EIA"], "brent daily");
  eq([q[1].priceUsd, q[1].frequency, q[1].source], [3.1, "monthly", "IMF"], "gas monthly");
  eq(preferPriced(energy, [], now)[0].quality, "unavailable", "nothing at all");
});
