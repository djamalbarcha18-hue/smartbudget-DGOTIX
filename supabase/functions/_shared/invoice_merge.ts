// Merging the readings of a long receipt read in strips (receipt-scan v2).
//
// The strips overlap a little so no line is cut, which means a line at the
// bottom of one strip can come back at the top of the next: those repeats
// are dropped. The header comes from the first strip that has it, the totals
// from the last. The app checks the arithmetic afterwards, so a wrong merge
// shows up as "needs review" rather than going unnoticed.

export type Item = { n: string; q: string; u: string; t: string; c: number };
export type Reading = Record<string, unknown> & { it?: Item[] };

const HEADER = ["inv", "dt", "cur", "sym", "sup", "cus", "cat"];
const TOTALS = ["sub", "dis", "tax", "tot", "paid", "due"];

function text(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function same(a: Item, b: Item): boolean {
  const norm = (s: string) => s.toLowerCase().replace(/\s+/g, " ").trim();
  return norm(a.n) === norm(b.n) && text(a.t) === text(b.t) &&
    text(a.q) === text(b.q);
}

/** Drops the first lines of [next] that repeat the last lines of [prev]. */
export function dropOverlap(prev: Item[], next: Item[], window = 3): Item[] {
  for (let k = Math.min(window, prev.length, next.length); k > 0; k--) {
    const tail = prev.slice(prev.length - k);
    const head = next.slice(0, k);
    if (tail.every((it, i) => same(it, head[i]))) return next.slice(k);
  }
  return next;
}

export function mergeReadings(parts: Reading[]): Reading {
  const out: Reading = { r: parts.some((p) => p.r !== false) };
  for (const k of HEADER) {
    out[k] = parts.map((p) => text(p[k])).find((v) => v !== "") ?? "";
  }
  for (const k of TOTALS) {
    out[k] = [...parts].reverse().map((p) => text(p[k])).find((v) => v !== "") ??
      "";
  }
  let items: Item[] = [];
  for (const p of parts) {
    const its = Array.isArray(p.it) ? p.it : [];
    items = items.concat(dropOverlap(items, its));
  }
  out.it = items;
  return out;
}
