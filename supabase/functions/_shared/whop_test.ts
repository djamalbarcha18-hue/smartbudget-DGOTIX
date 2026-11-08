import { buildWhopHeaders, whopApiVersion } from "./whop.ts";

function eq(a: unknown, b: unknown) {
  if (a !== b) throw new Error(`expected ${String(b)}, got ${String(a)}`);
}

Deno.test("whopApiVersion: only a YYYY-MM-DD date pins a version", () => {
  eq(whopApiVersion("2026-07-23"), "2026-07-23");
  eq(whopApiVersion(" 2026-07-23 "), "2026-07-23");
  eq(whopApiVersion(undefined), null);
  eq(whopApiVersion(""), null);
  eq(whopApiVersion("latest"), null);
  eq(whopApiVersion("2026-7-23"), null);
  eq(whopApiVersion("2026-10-27-1"), "2026-10-27-1");
  eq(whopApiVersion("2026-10-27-"), null);
  eq(whopApiVersion("2026-10-27-abc"), null);
});

Deno.test("buildWhopHeaders: the version header appears only when pinned", () => {
  const plain = buildWhopHeaders("k", null, { "Content-Type": "application/json" });
  eq(plain["Api-Version-Date"], undefined);
  eq(plain["Content-Type"], "application/json");
  eq(plain["Authorization"], "Bearer k");
  eq(buildWhopHeaders("k", "2026-07-23")["Api-Version-Date"], "2026-07-23");
});
