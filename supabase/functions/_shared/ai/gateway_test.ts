import { classify, DEFAULT_MODELS } from "./gateway.ts";

function expect(v: unknown, want: unknown, m: string) {
  if (JSON.stringify(v) !== JSON.stringify(want)) {
    throw new Error(`${m}: got ${JSON.stringify(v)}, want ${JSON.stringify(want)}`);
  }
}

Deno.test("a model that is gone (404) moves on to the next model", () => {
  expect(classify(404, "models/x is not found"), { code: "model_not_found", retryable: true }, "404");
  // A bad key or a bad request would fail the same way on any model.
  expect(classify(403, "permission denied").retryable, false, "403");
  expect(classify(400).retryable, false, "400");
  expect(classify(503).retryable, true, "503");
});

Deno.test("only Gemini aliases are used, no retired pinned ids", () => {
  const google = DEFAULT_MODELS.filter((m) => m.provider === "google").map((m) => m.id);
  expect(google.sort(), ["gemini-flash-latest", "gemini-flash-lite-latest"], "google models");
});
