// The size of one AI request (docs/AI_ARCHITECTURE.md, "Request limits"):
// at most 4,000 tokens in, 1,000 out, 5,000 in all. The output is capped at
// the provider (maxOutputTokens), so keeping the input under its limit keeps
// the total under its own. The input is FITTED, not refused: when it is too
// large the oldest conversation turns go first, then the tail of the
// financial context, so the user still gets an answer to a smaller question.
//
// Pure (no Deno or network), so it is tested on its own.

export const MAX_INPUT_TOKENS = 4000;
export const MAX_OUTPUT_TOKENS = 1000;
export const MAX_TOTAL_TOKENS = MAX_INPUT_TOKENS + MAX_OUTPUT_TOKENS;

export type Turn = { role: "user" | "assistant"; text: string };

// Section labels and separators the prompt builder adds around the parts.
const OVERHEAD_TOKENS = 60;
// Each conversation turn also carries its "User:" / "DGOTIX AI:" label.
const TURN_OVERHEAD_TOKENS = 8;

/**
 * A deliberately cautious estimate (never a lower count than the real one, so
 * a request counted as under the limit is under it): Gemini reads every digit
 * as a token and Arabic letters at roughly two characters a token, and
 * financial context is full of numbers.
 */
export function estimateTokens(text: string): number {
  let t = 0;
  for (const ch of text) {
    const c = ch.codePointAt(0)!;
    if (c >= 48 && c <= 57) t += 1; // digits: one token each
    else if ((c >= 0x600 && c <= 0x6ff) || (c >= 0x750 && c <= 0x77f)) t += 0.5;
    else if (c < 128) t += 0.3; // Latin letters, spaces, punctuation
    else t += 1; // anything else (CJK, emoji…): a token each
  }
  return Math.ceil(t);
}

/** The start of [text] that fits [tokens]: whole lines where it can. */
export function fitText(text: string, tokens: number): string {
  if (tokens <= 0) return "";
  if (estimateTokens(text) <= tokens) return text;
  const out: string[] = [];
  let used = 0;
  for (const line of text.split("\n")) {
    const c = estimateTokens(line) + 1;
    if (used + c > tokens) break;
    out.push(line);
    used += c;
  }
  if (out.length > 0) return out.join("\n");
  // One long line: shorten it until it fits.
  let s = text;
  while (s.length > 0 && estimateTokens(s) > tokens) {
    s = s.slice(0, Math.floor(s.length * 0.9));
  }
  return s;
}

export interface FitInput {
  /** The system prompt the provider will add (it counts as input). */
  system: string;
  context: string;
  history: Turn[];
  prompt: string;
}

export interface Fitted {
  context: string;
  history: Turn[];
  prompt: string;
  /** Something was cut to fit. */
  trimmed: boolean;
  /** Estimated input tokens after fitting. */
  tokens: number;
}

export function fitInput(i: FitInput, max: number = MAX_INPUT_TOKENS): Fitted {
  const base = estimateTokens(i.system) + OVERHEAD_TOKENS;
  // The question always keeps its place (it is already capped by characters);
  // only a question that alone overflows is shortened.
  let prompt = i.prompt;
  const promptRoom = Math.max(1, max - base);
  if (estimateTokens(prompt) > promptRoom) prompt = fitText(prompt, promptRoom);
  let rem = max - base - estimateTokens(prompt);

  const context = fitText(i.context, Math.max(0, rem));
  rem -= estimateTokens(context);

  // Newest turns are kept, oldest dropped first.
  const history: Turn[] = [];
  for (let k = i.history.length - 1; k >= 0; k--) {
    const c = estimateTokens(i.history[k].text) + TURN_OVERHEAD_TOKENS;
    if (c > rem) break;
    history.unshift(i.history[k]);
    rem -= c;
  }

  const trimmed = prompt !== i.prompt || context !== i.context ||
    history.length !== i.history.length;
  return { context, history, prompt, trimmed, tokens: max - Math.max(0, rem) };
}
