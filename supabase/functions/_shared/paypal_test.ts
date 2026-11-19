import { plausiblePaypalSignature, tokenLifetimeS } from "./paypal.ts";

function eq(a: unknown, b: unknown) {
  if (a !== b) throw new Error(`expected ${String(b)}, got ${String(a)}`);
}

const headers = (algo: string, cert: string) =>
  new Headers({ "paypal-auth-algo": algo, "paypal-cert-url": cert });

Deno.test("plausiblePaypalSignature: PayPal's own certificate hosts pass", () => {
  for (
    const cert of [
      "https://api.paypal.com/v1/notifications/certs/CERT-360caa42-fca2a594-1d93a270",
      "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-360caa42",
      "https://api-m.paypal.com/v1/notifications/certs/CERT-1",
      "https://api-m.sandbox.paypal.com/v1/notifications/certs/CERT-1",
    ]
  ) eq(plausiblePaypalSignature(headers("SHA256withRSA", cert)), true);
});

Deno.test("plausiblePaypalSignature: anything else is refused before calling PayPal", () => {
  const ok = "https://api.paypal.com/v1/notifications/certs/CERT-1";
  // Another algorithm, or none.
  eq(plausiblePaypalSignature(headers("HS256", ok)), false);
  eq(plausiblePaypalSignature(headers("", ok)), false);
  // Look-alike, foreign or insecure certificate URLs.
  for (
    const cert of [
      "",
      "http://api.paypal.com/v1/notifications/certs/CERT-1",
      "https://api.paypal.com.evil.example/v1/notifications/certs/CERT-1",
      "https://evil.example/api.paypal.com/v1/notifications/certs/CERT-1",
      "https://api.paypal.com@evil.example/v1/notifications/certs/CERT-1",
      "https://paypal.com/v1/notifications/certs/CERT-1",
      "https://api.paypal.com/v1/other/CERT-1",
      "https://api.paypal.com/v1/notifications/certs/",
      "https://api.paypal.com/v1/notifications/certs/CERT 1",
    ]
  ) eq(plausiblePaypalSignature(headers("SHA256withRSA", cert)), false);
});

Deno.test("tokenLifetimeS: reused until a minute before expiry, never when unknown", () => {
  eq(tokenLifetimeS(32400), 32340);
  eq(tokenLifetimeS("3600"), 3540);
  eq(tokenLifetimeS(60), 0);
  eq(tokenLifetimeS(30), 0);
  eq(tokenLifetimeS(undefined), 0);
  eq(tokenLifetimeS("soon"), 0);
  eq(tokenLifetimeS(-5), 0);
});
