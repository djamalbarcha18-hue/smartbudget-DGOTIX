import { allSandbox, foundingOffer, isSandboxUrl } from "./billing.ts";
import { hmacBase64, membershipIdOf, verifyWhopSignature, whopSign, whopStatus } from "./whop.ts";

const SECRET = "ws_test_secret";

async function headers(ts: number, body: string, id = "msg_1", secret = SECRET): Promise<Headers> {
  return new Headers({
    "webhook-id": id,
    "webhook-timestamp": String(ts),
    "webhook-signature": "v1," + await whopSign(secret, id, String(ts), body),
  });
}

function expect(v: boolean, want: boolean, m: string) {
  if (v !== want) throw new Error(`${m}: got ${v}`);
}

Deno.test("a fresh, correctly signed webhook is accepted", async () => {
  const now = 1_790_000_000;
  const body = '{"type":"membership.activated"}';
  expect(await verifyWhopSignature(body, await headers(now - 5, body), SECRET, now), true, "fresh");
});

Deno.test("Standard Webhooks: any of several signatures may match", async () => {
  const now = 1_790_000_000;
  const body = "{}";
  const h = await headers(now, body);
  h.set("webhook-signature", "v1,bm90LWl0 " + h.get("webhook-signature"));
  expect(await verifyWhopSignature(body, h, SECRET, now), true, "second entry");
});

Deno.test("the HMAC matches the Standard Webhooks spec's test vector", async () => {
  // github.com/standard-webhooks/standard-webhooks: whsec_ secrets are base64
  // keys there; Whop keys with its secret's own bytes instead (see whop.ts).
  const key = Uint8Array.from(atob("MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw"), (c) => c.charCodeAt(0));
  const sig = await hmacBase64(key, 'msg_p5jXN8AQM9LWM0D4loKWxJek.1614265330.{"test": 2432232314}');
  expect(sig === "g0hM9SsE+OTPJTGt/tmIKtSyZlE3uFJELVlNIOLJ1OE=", true, "spec signature " + sig);
});

Deno.test("an old or future-dated webhook is refused", async () => {
  const now = 1_790_000_000;
  const body = "{}";
  expect(await verifyWhopSignature(body, await headers(now - 301, body), SECRET, now), false, "old");
  expect(await verifyWhopSignature(body, await headers(now + 301, body), SECRET, now), false, "future");
});

Deno.test("a changed body, id or wrong secret is refused", async () => {
  const now = 1_790_000_000;
  const h = await headers(now, '{"amount":10}');
  expect(await verifyWhopSignature('{"amount":99}', h, SECRET, now), false, "body");
  expect(await verifyWhopSignature('{"amount":10}', h, "ws_other", now), false, "secret");
  h.set("webhook-id", "msg_2");
  expect(await verifyWhopSignature('{"amount":10}', h, SECRET, now), false, "id");
  const bad = await headers(now, "{}");
  bad.set("webhook-timestamp", "abc");
  expect(await verifyWhopSignature("{}", bad, SECRET, now), false, "bad ts");
  expect(await verifyWhopSignature("{}", new Headers(), SECRET, now), false, "no headers");
});

Deno.test("membership statuses map to ours", () => {
  expect(whopStatus("active")?.status === "active", true, "active");
  expect(whopStatus("canceling")?.status === "active" && whopStatus("canceling")?.cancelAtPeriodEnd === true, true, "canceling");
  expect(whopStatus("past_due")?.status === "past_due", true, "past_due");
  expect(whopStatus("expired")?.status === "canceled", true, "expired");
  expect(whopStatus("unresolved")?.status === "paused", true, "unresolved");
  expect(whopStatus("something_new") === null, true, "unknown");
});

Deno.test("the membership an event is about", () => {
  expect(membershipIdOf({ id: "mem_1" }) === "mem_1", true, "membership");
  expect(membershipIdOf({ id: "pay_1", membership: { id: "mem_2" } }) === "mem_2", true, "payment");
  expect(membershipIdOf({ id: "rfnd_1", payment: { membership_id: "mem_3" } }) === "mem_3", true, "refund");
  expect(membershipIdOf({ id: "prod_1" }) === null, true, "none");
});

Deno.test("only sandbox API hosts count as test accounts", () => {
  expect(isSandboxUrl("https://api-m.sandbox.paypal.com"), true, "paypal sandbox");
  expect(isSandboxUrl("https://sandbox-api.whop.com/api/v1"), true, "whop sandbox");
  expect(isSandboxUrl("https://api-m.paypal.com"), false, "paypal live");
  expect(isSandboxUrl("https://api.whop.com/api/v1"), false, "whop live");
  expect(isSandboxUrl("https://api.whop.com/sandbox-x"), false, "path only");
  expect(isSandboxUrl(""), false, "unset");
});

Deno.test("test mode needs every provider on its sandbox", () => {
  const paypal = "https://api-m.sandbox.paypal.com";
  const whop = "https://sandbox-api.whop.com/api/v1";
  expect(allSandbox([], { paypal }), false, "no provider");
  expect(allSandbox(["paypal"], { paypal }), true, "paypal sandbox");
  expect(allSandbox(["whop", "paypal"], { paypal, whop: "https://api.whop.com/api/v1" }), false, "whop live");
  expect(allSandbox(["whop", "paypal"], { paypal, whop }), true, "both sandbox");
  expect(allSandbox(["whop", "paypal"], { paypal: "https://api-m.paypal.com", whop }), false, "paypal live");
});

Deno.test("the founding offer runs only until its end date", () => {
  const now = new Date("2026-11-15T00:00:00Z");
  const o = foundingOffer({ endsAt: "2026-12-31T23:59:59Z" }, now);
  expect(o?.yearlyUsd === 39.99 && o?.endsAt === "2026-12-31T23:59:59.000Z", true, "running, default price");
  expect(foundingOffer({ endsAt: "2026-11-14T00:00:00Z" }, now) === null, true, "over");
  expect(foundingOffer({ endsAt: "" }, now) === null, true, "unset");
  expect(foundingOffer({ endsAt: "soon" }, now) === null, true, "unparsable");
  expect(foundingOffer({ endsAt: "2026-12-31", yearlyUsd: "29.99" }, now)?.yearlyUsd === 29.99, true, "own price");
  expect(foundingOffer({ endsAt: "2026-12-31", yearlyUsd: "free" }, now) === null, true, "bad price");
});
