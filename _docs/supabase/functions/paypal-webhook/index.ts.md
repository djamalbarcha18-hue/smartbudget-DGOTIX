<!-- METADATA: {"source_path": "supabase/functions/paypal-webhook/index.ts", "source_sha": "effa9eaaa06557819fe3b4fc3f97dfc9dced5ef3", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T11:21:15Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/functions/paypal-webhook/index.ts",
  "source_hash": "046b98107a06981df568b1f893bec1c59bb3a78d98349e55a2e0958d1979cf38",
  "last_updated": "2026-11-19T11:20:36.854211+00:00",
  "git_sha": "effa9eaaa06557819fe3b4fc3f97dfc9dced5ef3",
  "tokens_used": 2392,
  "complexity_score": 2,
  "estimated_review_time_minutes": 11,
  "external_dependencies": []
}
```

</details>

[Documentation Home](../../../README.md) > [supabase](../../README.md) > [functions](../README.md) > [paypal-webhook](./README.md) > **index**

---

# index.ts

> **File:** `supabase/functions/paypal-webhook/index.ts`

![Complexity: Low](https://img.shields.io/badge/Complexity-Low-green) ![Review Time: 11min](https://img.shields.io/badge/Review_Time-11min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This module implements a PayPal webhook endpoint and related helpers for verifying, processing, and responding to incoming PayPal events. It exposes four module-level functions: ok and signed for producing response payloads, apply for performing the domain-side application of a verified and first-seen event, and result for producing the final response after processing. The implementation relies on shared utilities for authentication (HttpError, serviceClient), billing event bookkeeping (markEventOnce, unmarkEvent, priceToPlan), and body handling (MAX_WEBHOOK_BYTES, readTextBody).

## Dependencies

### Internal Dependencies

| Module | Usage |
| --- | --- |
| `../_shared/auth.ts` | import { HttpError, serviceClient } from "../_shared/auth.ts"; |
| `../_shared/billing.ts` | import { markEventOnce, priceToPlan, unmarkEvent } from "../_shared/billing.ts"; |
| `../_shared/body.ts` | import { MAX_WEBHOOK_BYTES, readTextBody } from "../_shared/body.ts"; |

## 📁 Directory

This file is part of the **paypal-webhook** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- implements async handlers (apply is asynchronous)
- delegates authentication and persistence to a shared service client
- uses shared billing helpers for event deduplication (markEventOnce, unmarkEvent) and plan mapping (priceToPlan)
- limits and reads request bodies with a MAX_WEBHOOK_BYTES guard

## Maintenance Notes

- Produce standard success or signed response objects for webhook handling via ok and signed.
- Verify and apply a single PayPal event in an idempotent fashion using apply, coordinating billing bookkeeping and plan conversion.
- Read and limit incoming request bodies using readTextBody and MAX_WEBHOOK_BYTES before processing.
- Use shared authentication and database client utilities (HttpError, serviceClient) to access and modify persistent state during event handling.


---

## Functions and Classes


### ok

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def ok(body: unknown = { ok: true }) -> Response:
```

#### Description

Constructs and returns an HTTP Response object representing a successful/OK payload.

By default it uses a simple object { ok: true } but accepts any value to include in the response body.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `body` = `{ ok: true }` | `unknown` | ❌ | — |

#### Returns

**Type:** `Response`

—

#### Complexity

Not analyzed

---



### signed

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def signed(h):
```

#### Description

Checks whether the provided input is signed.

The function evaluates the given value to determine if it carries a valid signature according to the function's signing/verification logic.


h is the single input to the function and represents the item to be checked for a signature (for example a header, token, or payload containing signature information).

Returns a boolean indicating whether the provided input is considered signed/validly signed.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `h` | `Unknown` | ✅ | — |

#### Complexity

Not analyzed

---



### apply

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def apply(db: Json, token: string, type: string, resource: Json, eventAt: string | null) -> Promise<Response>:
```

#### Description

Applies a single, verified PayPal webhook event that has been seen for the first time.

It processes the provided event data and updates the system accordingly.


token is a string used to authenticate or validate the webhook event; resource is the JSON payload of the PayPal event; eventAt is an ISO timestamp string or null indicating when the event occurred (if known). The db parameter is a generic JSON handle representing database/context used for applying the event.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `db` | `Json` | ✅ | — |
| `token` | `string` | ✅ | — |
| `type` | `string` | ✅ | — |
| `resource` | `Json` | ✅ | — |
| `eventAt` | `string | null` | ✅ | — |

#### Returns

**Type:** `Promise<Response>`

—

#### Complexity

Not analyzed

---



### result

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def result(outcome: ApplyOutcome) -> Response:
```

#### Description

Constructs and returns an HTTP Response representing the result of applying some operation described by the provided ApplyOutcome.

This function maps the outcome into an appropriate Response object (status, headers, and body) to be sent back to the caller.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `outcome` | `ApplyOutcome` | ✅ | — |

#### Returns

**Type:** `Response`

—

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
