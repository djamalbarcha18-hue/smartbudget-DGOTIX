import { verifyPaddleSignature } from "./billing.ts";

const SECRET = "pdl_ntfset_test";

async function sign(ts: number, body: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${ts}:${body}`));
  const hex = Array.from(new Uint8Array(mac)).map((b) => b.toString(16).padStart(2, "0")).join("");
  return `ts=${ts};h1=${hex}`;
}

function expect(v: boolean, want: boolean, m: string) {
  if (v !== want) throw new Error(`${m}: got ${v}`);
}

Deno.test("a fresh, correctly signed webhook is accepted", async () => {
  const now = 1_790_000_000;
  const body = '{"event_id":"evt_1"}';
  expect(await verifyPaddleSignature(body, await sign(now - 5, body), SECRET, now), true, "fresh");
});

Deno.test("an old or future-dated webhook is refused", async () => {
  const now = 1_790_000_000;
  const body = '{"event_id":"evt_1"}';
  expect(await verifyPaddleSignature(body, await sign(now - 301, body), SECRET, now), false, "old");
  expect(await verifyPaddleSignature(body, await sign(now + 301, body), SECRET, now), false, "future");
});

Deno.test("a changed body or wrong secret is refused", async () => {
  const now = 1_790_000_000;
  const header = await sign(now, '{"amount":10}');
  expect(await verifyPaddleSignature('{"amount":99}', header, SECRET, now), false, "body");
  expect(await verifyPaddleSignature('{"amount":10}', header, "other", now), false, "secret");
  expect(await verifyPaddleSignature('{"amount":10}', "ts=abc;h1=00", SECRET, now), false, "bad ts");
});
