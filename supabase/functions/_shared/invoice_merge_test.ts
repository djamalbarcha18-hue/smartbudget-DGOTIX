import { dropOverlap, mergeReadings } from "./invoice_merge.ts";
const it = (n: string, t: string) => ({ n, q: "1", u: t, t, c: 0.9 });
function eq(a: unknown, b: unknown, m: string) {
  if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error(`${m}: ${JSON.stringify(a)} != ${JSON.stringify(b)}`);
}
Deno.test("repeated boundary lines are dropped", () => {
  eq(dropOverlap([it("A","1"), it("B","2"), it("C","3")], [it("C","3"), it("D","4")]).map((x) => x.n), ["D"], "one");
  eq(dropOverlap([it("A","1"), it("B","2")], [it("A","1"), it("B","2"), it("E","5")]).map((x) => x.n), ["E"], "two");
  eq(dropOverlap([it("A","1")], [it("Z","9")]).map((x) => x.n), ["Z"], "none");
});
Deno.test("header from the first part, totals from the last", () => {
  const m = mergeReadings([
    { r: true, inv: "F-1", dt: "2026-09-05", cur: "EUR", sym: "€", sup: "Shop", cus: "", cat: "التسوق", it: [it("A","1"), it("B","2")], sub: "", tot: "" },
    { r: true, inv: "", dt: "", cur: "", sym: "", sup: "", cus: "", cat: "", it: [it("B","2"), it("C","3")], sub: "6,00", tot: "6,00" },
  ]);
  eq(m.inv, "F-1", "inv"); eq(m.sup, "Shop", "sup"); eq(m.tot, "6,00", "tot");
  eq((m.it as {n:string}[]).map((x) => x.n), ["A","B","C"], "items");
});
