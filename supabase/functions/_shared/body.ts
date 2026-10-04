// Request bodies with a size limit, so an oversized request is refused
// before it can cost anything (model tokens, memory).
import { HttpError } from "./auth.ts";

/**
 * The JSON body of [req], or {} when it isn't valid JSON. Throws
 * HttpError(413, "too_large") as soon as more than [maxBytes] arrive.
 */
export async function readJsonBody(
  req: Request,
  maxBytes: number,
  // deno-lint-ignore no-explicit-any
): Promise<any> {
  const declared = Number(req.headers.get("content-length") ?? "0");
  if (declared > maxBytes) throw new HttpError(413, "too_large");
  if (!req.body) return {};

  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > maxBytes) {
      await reader.cancel().catch(() => {});
      throw new HttpError(413, "too_large");
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size);
  let at = 0;
  for (const c of chunks) {
    bytes.set(c, at);
    at += c.byteLength;
  }
  try {
    return JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    return {};
  }
}

/** [text] cut to at most [max] characters. */
export function capText(text: string, max: number): string {
  return text.length <= max ? text : text.slice(0, max);
}
