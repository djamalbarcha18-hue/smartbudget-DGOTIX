import { AI_QUOTA, allowanceFor, OCR_QUOTA, quotaInfo, trustOf } from "./quota.ts";

function expect(v: unknown, want: unknown, m: string) {
  if (JSON.stringify(v) !== JSON.stringify(want)) {
    throw new Error(`${m}: got ${JSON.stringify(v)}, want ${JSON.stringify(want)}`);
  }
}

const now = new Date("2026-10-20T12:00:00Z");
const daysAgo = (d: number) => new Date(now.getTime() - d * 86_400_000).toISOString();

Deno.test("paying beats everything; age and confirmation decide the rest", () => {
  expect(trustOf("pro", { createdAt: daysAgo(0), emailConfirmed: false }, now), "paid", "paid");
  expect(trustOf("free", { createdAt: daysAgo(30), emailConfirmed: true }, now), "established", "old");
  expect(trustOf("free", { createdAt: daysAgo(6), emailConfirmed: true }, now), "new", "6 days");
  expect(trustOf("free", { createdAt: daysAgo(7), emailConfirmed: true }, now), "established", "7 days");
  expect(trustOf("free", { createdAt: daysAgo(90), emailConfirmed: false }, now), "new", "unconfirmed");
  expect(trustOf("free", { createdAt: null, emailConfirmed: true }, now), "new", "unknown age");
  expect(trustOf("free", { createdAt: "garbage", emailConfirmed: true }, now), "new", "bad date");
});

Deno.test("a new account gets at most the new-account allowance", () => {
  expect(allowanceFor(AI_QUOTA.pro, "ai", "new"), { limit: 10, window: "monthly" }, "pro ai");
  expect(allowanceFor(OCR_QUOTA.pro, "ocr", "new"), { limit: 5, window: "monthly" }, "pro ocr");
  expect(allowanceFor(AI_QUOTA.free, "ai", "new"), AI_QUOTA.free, "free stays lower");
  expect(allowanceFor(AI_QUOTA.pro, "ai", "established"), AI_QUOTA.pro, "established");
  expect(allowanceFor(AI_QUOTA.pro, "ai", "paid"), AI_QUOTA.pro, "paid");
});

Deno.test("PRO gets 80 a month, none carried over", () => {
  expect(AI_QUOTA.pro, { limit: 80, window: "monthly" }, "pro ai");
});

Deno.test("what the app is told: left, and when a month starts over", () => {
  const info = quotaInfo(AI_QUOTA.pro, 30, now);
  expect(info.remaining, 50, "left");
  expect(info.resetsAt, "2026-11-01T00:00:00.000Z", "next month");
  expect(quotaInfo(AI_QUOTA.pro, 80, now).remaining, 0, "spent");
  expect(quotaInfo(AI_QUOTA.pro, 95, now).remaining, 0, "never negative");
  expect(quotaInfo(AI_QUOTA.free, 2, now).resetsAt, null, "one-time has no reset");
  expect(quotaInfo(AI_QUOTA.pro, 79, new Date("2026-12-31T23:59:00Z")).resetsAt,
    "2027-01-01T00:00:00.000Z", "year end");
});
