<!-- METADATA: {"source_path": "supabase/functions/ai-gateway/index.ts", "source_sha": "2e8f471c8c616df22e60baaf03f53cfb3e88c9c1", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T11:21:15Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/functions/ai-gateway/index.ts",
  "source_hash": "61500d83355bfc00f9a84fb330ac9039e92ed078171389f2515b72d4f590c2fa",
  "last_updated": "2026-11-19T11:20:44.145157+00:00",
  "git_sha": "2e8f471c8c616df22e60baaf03f53cfb3e88c9c1",
  "tokens_used": 3723,
  "complexity_score": 3,
  "estimated_review_time_minutes": 17,
  "external_dependencies": []
}
```

</details>

[Documentation Home](../../../README.md) > [supabase](../../README.md) > [functions](../README.md) > [ai-gateway](./README.md) > **index**

---

# index.ts

> **File:** `supabase/functions/ai-gateway/index.ts`

![Complexity: Low](https://img.shields.io/badge/Complexity-Low-green) ![Review Time: 17min](https://img.shields.io/badge/Review_Time-17min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This module implements utility routines used by an AI gateway function in a Supabase environment. It provides helpers for generating monthly keys, truncating strings, sanitizing and building conversational history prompts, enforcing input token budgets, and recording usage. Several functions interact with shared project utilities for CORS, authentication, request body handling, and AI budget management. Two functions, bumpUsage and log, are asynchronous and integrate with service clients or persistence to record consumption and diagnostics.

## Dependencies

### Internal Dependencies

| Module | Usage |
| --- | --- |
| `../_shared/cors.ts` | import { corsHeaders, jsonResponse } from "../_shared/cors.ts"; |
| `../_shared/auth.ts` | import { HttpError, requireAccount, serviceClient } from "../_shared/auth.ts"; |
| `../_shared/body.ts` | import { capText, readJsonBody } from "../_shared/body.ts"; |
| `../_shared/ai/budget.ts` | import { fitInput, MAX_INPUT_TOKENS, type Turn } from "../_shared/ai/budget.ts"; |

## 📁 Directory

This file is part of the **ai-gateway** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- Contains both synchronous helpers and asynchronous operations for persistence (async/await in bumpUsage and log).
- Delegates cross-cutting concerns to shared modules (CORS, auth, body parsing, and AI budgeting).
- Enforces input size and token budgets using dedicated budget utilities (fitInput, MAX_INPUT_TOKENS, Turn).

## Maintenance Notes

- Create a month-based key string for usage or storage partitioning (monthKey).
- Truncate or pad text values to a given length boundary (left).
- Sanitize conversational turn history and construct a combined prompt while respecting token limits (sanitizeHistory and buildPrompt).
- Record AI usage metrics and persist logging information via async service clients (bumpUsage and log).
- Integrate input handling utilities such as reading JSON bodies and capping text to enforce size constraints (via readJsonBody and capText usage).


---

## Functions and Classes


### monthKey

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def monthKey() -> string:
```

#### Description

Produces and returns a month-based key as a string.

The function is intended to provide a concise identifier representing a month (for example for grouping, naming, or caching purposes).

#### Returns

**Type:** `string`

—

#### Complexity

Not analyzed

---



### left

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def left(used: number):
```

#### Description

Computes how much is left given an amount that has already been used.

The function accepts a numeric `used` value and determines the remaining quantity based on that input.


Returns the remaining quantity (typically as a number) after accounting for the provided `used` amount.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `used` | `number` | ✅ | — |

#### Complexity

Not analyzed

---



### sanitizeHistory

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def sanitizeHistory(raw: unknown) -> Turn[]:
```

#### Description

Takes an arbitrary input value and normalizes or validates it into a canonical array of conversation turns.

The function ensures the raw data is converted to and returned as an array of Turn objects suitable for downstream processing in the AI gateway.


raw is an unknown, possibly untrusted or loosely-typed payload (for example a deserialized JSON value); the function parses, sanitizes, and coerces that input into the expected Turn[] structure, handling missing or malformed fields as needed.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `raw` | `unknown` | ✅ | — |

#### Returns

**Type:** `Turn[]`

—

#### Complexity

Not analyzed

---



### buildPrompt

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def buildPrompt(context: string, history: Turn[], prompt: string) -> string:
```

#### Description

Constructs the final textual prompt sent to the AI by combining a provided context, an array of prior conversation turns, and the current user prompt into one cohesive string.

It formats and merges these pieces so the AI receives the conversation history plus any contextual grounding before the new prompt.


context is a grounding string (system or contextual information), history is an array of Turn objects representing prior dialogue turns, and prompt is the current user input to be appended or integrated into the assembled prompt.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `context` | `string` | ✅ | — |
| `history` | `Turn[]` | ✅ | — |
| `prompt` | `string` | ✅ | — |

#### Returns

**Type:** `string`

—

#### Complexity

Not analyzed

---



### bumpUsage

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def bumpUsage(db: ReturnType<typeof serviceClient>, userId: string, month: string, inTok: number, outTok: number, cost: number, // The request itself was already counted by reserveUsage: add only the
  // tokens and cost.
  counted = false) -> Promise<void>:
```

#### Description

Updates a user's monthly usage record in the provided Supabase service client by adding input/output token counts and cost.

It increments stored counters for the specified user and month; the request itself is assumed to have been previously recorded by reserveUsage so only the additional tokens and cost are applied.


Most parameters are self-explanatory: db is the Supabase service client, userId and month identify the usage row, and inTok/outTok/cost are the amounts to add. The optional counted flag (default false) indicates whether the request portion has already been counted elsewhere and controls whether any additional request-count bookkeeping should be applied.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `db` | `ReturnType<typeof serviceClient>` | ✅ | — |
| `userId` | `string` | ✅ | — |
| `month` | `string` | ✅ | — |
| `inTok` | `number` | ✅ | — |
| `outTok` | `number` | ✅ | — |
| `cost` | `number` | ✅ | — |
| `// The request itself was already counted by reserveUsage` = `false` | `add only the
  // tokens and cost.
  counted` | ❌ | — |

#### Returns

**Type:** `Promise<void>`

—

#### Complexity

Not analyzed

---



### log

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def log(db: ReturnType<typeof serviceClient>, userId: string, task: string, provider: string | null, model: string | null, fallbackUsed: boolean, latencyMs: number, inTok: number, outTok: number, cost: number, errorCode: string | null) -> Promise<void>:
```

#### Description

Asynchronously records an AI gateway invocation into a backing database.

It stores metadata about the call such as the user who made the request, the task performed, the provider and model used (if any), whether a fallback was used, timing and token usage, cost, and any error code.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `db` | `ReturnType<typeof serviceClient>` | ✅ | — |
| `userId` | `string` | ✅ | — |
| `task` | `string` | ✅ | — |
| `provider` | `string | null` | ✅ | — |
| `model` | `string | null` | ✅ | — |
| `fallbackUsed` | `boolean` | ✅ | — |
| `latencyMs` | `number` | ✅ | — |
| `inTok` | `number` | ✅ | — |
| `outTok` | `number` | ✅ | — |
| `cost` | `number` | ✅ | — |
| `errorCode` | `string | null` | ✅ | — |

#### Returns

**Type:** `Promise<void>`

—

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
