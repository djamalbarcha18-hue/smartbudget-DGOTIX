import {
  estimateTokens,
  fitInput,
  fitText,
  MAX_INPUT_TOKENS,
  MAX_OUTPUT_TOKENS,
  MAX_TOTAL_TOKENS,
  type Turn,
} from "./budget.ts";

function expect(v: unknown, want: unknown, m: string) {
  if (JSON.stringify(v) !== JSON.stringify(want)) {
    throw new Error(`${m}: got ${JSON.stringify(v)}, want ${JSON.stringify(want)}`);
  }
}
function ok(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const SYSTEM = "x".repeat(3700); // about the real system prompt

Deno.test("the policy's three limits", () => {
  expect(MAX_INPUT_TOKENS, 4000, "in");
  expect(MAX_OUTPUT_TOKENS, 1000, "out");
  expect(MAX_TOTAL_TOKENS, 5000, "total");
});

Deno.test("digits cost a token each, Arabic about half, Latin less", () => {
  expect(estimateTokens("1234567890"), 10, "digits");
  expect(estimateTokens("مرحبا"), 3, "arabic");
  ok(estimateTokens("hello world") < 6, "latin");
  expect(estimateTokens(""), 0, "empty");
});

Deno.test("a normal request is left exactly as it was", () => {
  const history: Turn[] = [{ role: "user", text: "ما رصيدي؟" }, { role: "assistant", text: "رصيدك جيد." }];
  const r = fitInput({ system: SYSTEM, context: "income: 4368\nexpenses: 1500", history, prompt: "كيف أوفر؟" });
  expect(r.trimmed, false, "not trimmed");
  expect(r.history, history, "history kept");
});

Deno.test("a huge context is cut to fit and the total stays under the limit", () => {
  const context = Array.from({ length: 4000 }, (_, i) => `line ${i}: ${i * 1234567}`).join("\n");
  const r = fitInput({ system: SYSTEM, context, history: [], prompt: "question" });
  ok(r.trimmed, "trimmed");
  ok(r.context.length < context.length, "shorter");
  ok(r.tokens <= MAX_INPUT_TOKENS, `input ${r.tokens} within ${MAX_INPUT_TOKENS}`);
  ok(r.tokens + MAX_OUTPUT_TOKENS <= MAX_TOTAL_TOKENS, "total within 5000");
  ok(r.context.startsWith("line 0:"), "the start of the context is kept");
});

Deno.test("old conversation turns go first, newest stay", () => {
  const turns: Turn[] = Array.from({ length: 6 }, (_, i) => ({
    role: i % 2 ? "assistant" : "user" as "user" | "assistant",
    text: `turn ${i} ` + "٠١٢".repeat(250),
  }));
  const r = fitInput({ system: SYSTEM, context: "", history: turns, prompt: "q" }, 1900);
  ok(r.history.length < turns.length, "some dropped");
  expect(r.history[r.history.length - 1].text, turns[5].text, "newest kept");
});

Deno.test("only a question that alone overflows is shortened", () => {
  const r = fitInput({ system: "s", context: "", history: [], prompt: "1".repeat(9000) }, 500);
  ok(r.trimmed, "trimmed");
  ok(estimateTokens(r.prompt) <= 500, "prompt fits");
});

Deno.test("fitText prefers whole lines", () => {
  expect(fitText("aaaaaaaaaa\nbbbbbbbbbb\ncccccccccc", 9), "aaaaaaaaaa\nbbbbbbbbbb", "two whole lines");
  expect(fitText("abc", 0), "", "no room");
});
