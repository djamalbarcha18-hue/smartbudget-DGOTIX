<!-- METADATA: {"source_path": "supabase/tests/functions_test.ts", "source_sha": "743b076ab9586e97b4f9fa5e076a969aa686e3a3", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T11:21:15Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/tests/functions_test.ts",
  "source_hash": "8fcf7e26526456dc7634b4bde063610400b4cab0c44a2262bd968531ccb05e31",
  "last_updated": "2026-11-19T11:21:15.018911+00:00",
  "git_sha": "743b076ab9586e97b4f9fa5e076a969aa686e3a3",
  "tokens_used": 8750,
  "complexity_score": 5,
  "estimated_review_time_minutes": 14,
  "external_dependencies": []
}
```

</details>

[Documentation Home](../../README.md) > [supabase](../README.md) > [tests](./README.md) > **functions_test**

---

# functions_test.ts

> **File:** `supabase/tests/functions_test.ts`

![Complexity: Medium](https://img.shields.io/badge/Complexity-Medium-yellow) ![Review Time: 14min](https://img.shields.io/badge/Review_Time-14min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This TypeScript test module contains a collection of utility and test helper functions used for exercising payment and subscription-related behavior in the Supabase test harness. It imports a set of harness utilities and mocks (including check, db, finish, load, model, outbound, paypal, paypalHeaders, paypalSub, PRICES, whop, whopCheckouts, whopHeaders, whopMem, whopMemberships) and exposes helpers for invoking and inspecting simulated calls, building request payloads, encoding data, generating JWTs, scanning and manipulating dates, and performing basic create/delete operations against the test environment. Several functions are asynchronous, indicating integration with async test flows, and the module also explicitly sets and deletes various environment variables (for example OCR_TIMEOUT_MS, AI_TIMEOUT_MS, FOUNDING_OFFER_ENDS_AT, PAYPAL_API_URL, WHOP_API_URL, and PAY_TEST_USER_IDS) to configure the test runtime.

The module-level functions include straightforward utilities such as calls, last, lastPlan, scan, nextMonth, before, stuckUsed, ask, askBody, cfg, b64, jwt and D, together with async routines checkout, yearly and del. These functions collectively support constructing test requests, encoding and signing payloads, manipulating time-related test state, and driving checkout/subscription test scenarios against mocked PayPal and Whop endpoints configured by the harness imports and environment variable adjustments.

## Dependencies

### Internal Dependencies

| Module | Usage |
| --- | --- |
| `./harness.ts` | import { check, db, finish, load, model, outbound, paypal, paypalHeaders, paypalSub, PRICES, whop, whopCheckouts, whopHeaders, whopMem, whopMemberships } from "./harness.ts"; |

## 📁 Directory

This file is part of the **tests** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- Uses asynchronous functions for operations that interact with external or simulated services (checkout, yearly, del).
- Centralized test-harness imports provide mocks and fixtures for payment providers and database interactions.
- Explicit environment variable manipulation to control test runtime configuration.

## Maintenance Notes

- Provide utilities to inspect and retrieve simulated outbound calls and the most recent call state (calls, last).
- Construct and encode request payloads and authentication tokens for tests (ask, askBody, b64, jwt).
- Support date and subscription-related computations and manipulations for tests (scan, nextMonth, before, yearly, lastPlan, stuckUsed).
- Drive payment checkout and deletion scenarios asynchronously against the test harness (checkout, del).
- Configure and tear down environment-specific settings required by the tests via explicit environment variable modifications.


---

## Registered at Module Level

- `Deno.env.set("OCR_TIMEOUT_MS")`
- `Deno.env.set("AI_TIMEOUT_MS")`
- `Deno.env.set("FOUNDING_OFFER_ENDS_AT")`
- `Deno.env.set("FOUNDING_OFFER_ENDS_AT")`
- `Deno.env.delete("FOUNDING_OFFER_ENDS_AT")`
- `Deno.env.set("PAYPAL_API_URL")`
- `Deno.env.set("WHOP_API_URL")`
- `Deno.env.delete("PAY_TEST_USER_IDS")`
- `Deno.env.set("PAY_TEST_USER_IDS")`
- `Deno.env.set("PAYPAL_API_URL")`
- `Deno.env.set("WHOP_API_URL")`
- `Deno.env.delete("PAY_TEST_USER_IDS")`



---

## Functions and Classes


### calls

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def calls():
```

#### Description

A test function named calls that executes test logic related to the 'calls' behavior in the supabase/tests/functions_test.ts file.

It organizes and runs the assertions or steps needed to verify functionality associated with calls.

#### Complexity

Not analyzed

---



### last

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def last():
```

#### Description

The extracted data only provides the function name and signature (function last() ) from a test file; no implementation or docstring is available, so the specific behavior is not specified.

Based on the available information, it is a parameterless function named last defined in supabase/tests/functions_test.ts, likely intended for use within the test suite.

#### Complexity

Not analyzed

---



### checkout

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def checkout(u: string):
```

#### Description

Asynchronously performs a checkout operation for the entity identified by the provided string.

The function carries out whatever steps are required to complete the checkout process for that identifier (for example, checking out a user, item, or resource).


u is a string that identifies the target of the checkout operation (for example, a user id, item id, or resource key); the function uses this identifier to locate and perform the checkout.

Returns a Promise that resolves when the checkout operation completes, containing the outcome or result of the operation.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `u` | `string` | ✅ | — |

#### Complexity

Not analyzed

---



### yearly

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def yearly(u: string):
```

#### Description

An asynchronous test helper named yearly that accepts a single string argument 'u' and performs asynchronous operations related to yearly behavior in the supabase/tests/functions_test.ts file.

It is intended to be used in the test suite to exercise or verify functionality that depends on the provided string input.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `u` | `string` | ✅ | — |

#### Complexity

Not analyzed

---



### lastPlan

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def lastPlan():
```

#### Description

Returns the most recent plan used by the test suite.

This function retrieves the last (most recently created or recorded) plan for inspection or assertions within tests.


The most recently recorded plan (the exact shape/type is not specified in the signature).

#### Complexity

Not analyzed

---



### scan

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def scan():
```

#### Description

Runs a scan operation as part of the test suite in supabase/tests/functions_test.ts, exercising the code path that performs scanning behavior (e.g., iterating or inspecting items) and verifying its correctness.

#### Complexity

Not analyzed

---



### nextMonth

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def nextMonth(x: any):
```

#### Description

A function named nextMonth that, given an input value x, is intended to produce or compute the “next month” based on that input.

The exact behavior (e.g., whether x is a date, month index, or string) is not specified by the signature alone.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `x` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### before

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def before(x: any):
```

#### Description

Defines a function named before that accepts a single argument.

It is intended to perform some operation using that argument (likely a preparatory or precondition action), but the exact behavior is not specified in the extracted signature.


The signature does not specify a return type or value, so the return behavior is not defined in the extracted data.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `x` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### stuckUsed

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def stuckUsed(x: any):
```

#### Description

stuckUsed is a function that takes a single argument and performs an operation identified by the name stuckUsed.

The exact behavior is not specified by the extracted signature; it simply accepts a value of any type and uses it within the function's implementation.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `x` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### ask

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def ask(u: string):
```

#### Description

Defines a function named ask that accepts a single string argument.

The specific behavior is not specified by the signature alone and depends on the implementation in supabase/tests/functions_test.ts.


The signature does not specify a return type, so the function may return void or any other value depending on its implementation; the exact return value is not determined from the extracted information.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `u` | `string` | ✅ | — |

#### Complexity

Not analyzed

---



### askBody

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def askBody(u: string, body: unknown):
```

#### Description

askBody is a helper function that takes a string identifier u and an arbitrary body value; it is intended to handle or work with the provided body in the context identified by u (for example, attaching or submitting a request body for the given URL or endpoint in tests).

The signature does not specify a return type, so the function's return value is not indicated by the extracted data and may be void or any other type.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `u` | `string` | ✅ | — |
| `body` | `unknown` | ✅ | — |

#### Complexity

Not analyzed

---



### cfg

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def cfg(u: string):
```

#### Description

cfg is a function that accepts a single string argument named u.

The extracted signature does not specify its behavior or side effects, so the precise operation performed by the function is not available from the provided data.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `u` | `string` | ✅ | — |

#### Complexity

Not analyzed

---



### b64

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def b64(o: any):
```

#### Description

This function is declared as b64 and accepts a single argument; the signature alone does not specify what operation it performs (for example, encoding, decoding, transformation, etc.).

The exact behavior must be determined from the implementation or surrounding tests.


The return value is not specified by the signature and is therefore unknown from the extracted data.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `o` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### jwt

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def jwt(sub: string, signedInAgoMs: number | null):
```

#### Description

Generate a JSON Web Token (JWT) for a given subject identifier.

The function creates a token for the provided sub and can simulate a token that was signed some time in the past when given a non-null signedInAgoMs.


sub is the subject identifier to embed in the token. signedInAgoMs, if non-null, is the number of milliseconds in the past to treat as the token's signing time (used to adjust issued-at/related timestamps); null means no artificial past offset.

Returns the generated JWT as a string representing the token for the given subject with any requested signing-time offset.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `sub` | `string` | ✅ | — |
| `signedInAgoMs` | `number | null` | ✅ | — |

#### Complexity

Not analyzed

---



### del

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def del(token: string):
```

#### Description

Asynchronously performs a delete operation within the test suite, using the provided token to authorize the request.

It is intended for use in supabase/tests/functions_test.ts to invoke a deletion/cleanup step during testing.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `token` | `string` | ✅ | — |

#### Complexity

Not analyzed

---



### D

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def D(n: number):
```

#### Description

Takes a single numeric argument n and performs the function's operation using that value.

The specific operation is determined by the function implementation in supabase/tests/functions_test.ts.


The signature does not specify a return type; the function may return a value or void depending on its implementation.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `n` | `number` | ✅ | — |

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
