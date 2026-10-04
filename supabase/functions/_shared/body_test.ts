import { HttpError } from "./auth.ts";
import { capText, readJsonBody } from "./body.ts";

function streamed(text: string): Request {
  // A streamed body carries no content-length, like a chunked upload.
  const bytes = new TextEncoder().encode(text);
  const body = new ReadableStream<Uint8Array>({
    start(c) {
      for (let i = 0; i < bytes.length; i += 1000) c.enqueue(bytes.slice(i, i + 1000));
      c.close();
    },
  });
  return new Request("http://x/", { method: "POST", body });
}

async function tooLarge(p: Promise<unknown>): Promise<boolean> {
  try {
    await p;
    return false;
  } catch (e) {
    return e instanceof HttpError && e.status === 413 && e.code === "too_large";
  }
}

Deno.test("a body within the limit is parsed", async () => {
  const req = new Request("http://x/", { method: "POST", body: '{"prompt":"hi"}' });
  const body = await readJsonBody(req, 100);
  if (body.prompt !== "hi") throw new Error("not parsed");
});

Deno.test("invalid JSON reads as an empty body", async () => {
  const req = new Request("http://x/", { method: "POST", body: "not json" });
  if (JSON.stringify(await readJsonBody(req, 100)) !== "{}") throw new Error("not empty");
});

Deno.test("an oversized body is refused, declared or streamed", async () => {
  const big = JSON.stringify({ prompt: "x".repeat(5000) });
  const declared = new Request("http://x/", { method: "POST", body: big });
  if (!(await tooLarge(readJsonBody(declared, 1000)))) throw new Error("declared");
  if (!(await tooLarge(readJsonBody(streamed(big), 1000)))) throw new Error("streamed");
});

Deno.test("text is capped", () => {
  if (capText("abcdef", 3) !== "abc") throw new Error("not capped");
  if (capText("ab", 3) !== "ab") throw new Error("changed");
});
