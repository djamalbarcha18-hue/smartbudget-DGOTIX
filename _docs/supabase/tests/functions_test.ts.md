<!-- METADATA: {"source_path": "supabase/tests/functions_test.ts", "source_sha": "212a3f8dc674919a630684d4edb2f3e3c5306acf", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T21:41:34Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/tests/functions_test.ts",
  "source_hash": "3e2c59abba6a8c547d248c068d6a9ec8c0d09963d75b85d7982f7986ba82f477",
  "last_updated": "2026-11-19T21:41:08.603730+00:00",
  "git_sha": "212a3f8dc674919a630684d4edb2f3e3c5306acf",
  "tokens_used": 7800,
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

This TypeScript test module contains a collection of standalone helper functions and test utilities used by the supabase/functions test suite. It defines 16 module-level functions that perform tasks such as generating payloads or headers (ask, askBody, cfg, b64, jwt), manipulating test state (calls, last, lastPlan, scan, nextMonth, before, stuckUsed), and executing asynchronous test flows (checkout, yearly, del). The file also performs numerous environment variable manipulations at module load time to configure timeouts, API endpoints, promotional windows, and test user IDs for external services like PayPal and Whop, which are important for shaping the test environment for payment- and subscription-related scenarios.

The utilities are designed to be used directly by tests to create and examine test conditions, simulate checkout flows, and manage mock or integration interactions with outbound services. Several functions are asynchronous to accommodate remote or time-dependent operations, and the module-level environment setup indicates that tests relying on these utilities expect to run with specific external API URLs and feature flags configured dynamically during the test run.

## Dependencies

### Internal Dependencies

| Module | Usage |
| --- | --- |
| `./harness.ts` | import { check, db, finish, load, model, outbound, paypal, paypalHeaders, paypalSub, PRICES, whop, whopCheckouts, whopHeaders, whopMem, whopMemberships } from "./harness.ts"; |

## 📁 Directory

This file is part of the **tests** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- Multiple async module-level functions indicating support for asynchronous test operations
- Extensive runtime manipulation of environment variables to configure external service endpoints and test feature windows
- Separation of small focused utilities for payload/header generation, state inspection, and control-flow helpers

## Maintenance Notes

- Provide helper functions for constructing test input and authentication artifacts (ask, askBody, cfg, b64, jwt).
- Expose utilities for inspecting and manipulating recorded test calls or state (calls, last, lastPlan, scan, nextMonth, before, stuckUsed).
- Implement asynchronous test flows for payment and subscription scenarios (checkout, yearly, del).
- Configure and modify process environment variables to control timeouts, API endpoints, promotional windows, and test user identifiers for external services (PayPal, Whop) at module load time.


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

A test routine defined in the supabase/tests/functions_test.ts file intended to exercise or verify behavior related to function calls.

It likely groups assertions or test cases that exercise calling Supabase functions or the code paths concerned with invoking those functions.

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

A parameterless function named last, likely intended to obtain or test the last element of a collection or sequence (based on its name and location in a tests file).

Returns the last element of a collection or sequence (or possibly undefined/null if the collection is empty).

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

Asynchronously performs a checkout-related operation using the provided string identifier.

The function name implies it initiates or completes a checkout process for the supplied entity.


u is a string that identifies the target of the checkout operation (for example, a user id, session id, or resource key); its exact semantics are determined by the surrounding test context.

Returns a Promise that resolves when the asynchronous checkout operation completes; the specific resolved value is not specified by the signature.

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

An asynchronous helper/test function named yearly that performs some asynchronous operations tied to a provided string identifier.

It is intended to run as part of the test suite in supabase/tests/functions_test.ts and likely exercises functionality scoped to a yearly context.


Returns a Promise that resolves when the asynchronous work is complete (no specific return type is declared).

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

A test helper that obtains the most recent 'plan' used or created within the test suite.

It is intended to return the last plan entry so tests can inspect or assert against it.


Returns the most recent plan (the last plan record or value) produced or available to the tests.

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

Performs a scan operation used in the test suite for supabase functions.

The function likely executes or validates a scanning-related behavior within tests in supabase/tests/functions_test.ts.

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

Interprets the input x and produces the month that follows it (i.e., the "next month").

The exact interpretation of x is not specified here, but the function name indicates it advances a month based on the provided value.


Returns a value representing the month after the one represented by x; the exact return type and format depend on how x is provided and processed.

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

A function named before that accepts a single argument; the specific behavior is not described in the available signature.

It is declared in supabase/tests/functions_test.ts and likely used as a test helper given its filename and name, but its exact actions are not specified here.


The return value is not specified by the provided signature and therefore is unknown from the extracted information.

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

A small test helper that accepts a value and ensures it is treated as used (typically to avoid unused-variable warnings) without performing any meaningful transformation.

x: any — the value to be marked/treated as used; its type is not important to the helper.

Returns void (no meaningful return value).

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

ask is a function that takes a single string argument named u and performs an 'ask' operation using that string.

Based on the signature alone, it is intended to initiate or handle some action or query related to the provided string.


The signature does not indicate a return type or value, so the return behavior is not specified in the extracted information.

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

Takes a URL string and an accompanying request body value and is intended to be used in tests to send or prepare a request body for the given URL.

It pairs the target location (u) with the provided payload (body) for use inside test cases.

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

The extracted signature does not specify its behavior, so its specific action (e.g., configuring, parsing, or validating based on the string) is not determined from the provided data.

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

Converts the given input value into a base64-encoded representation.

The function accepts any JavaScript value and produces a base64 string form of that value.


o: the value to be encoded; accepts any type (primitive, object, buffer, etc.) and will be transformed to a form suitable for base64 encoding.

A base64-encoded string representing the provided input.

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

Creates a JSON Web Token (JWT) for the given subject identifier.

The optional signedInAgoMs parameter allows the token's timing (e.g., issued-at) to reflect that the subject signed in a specified number of milliseconds in the past.


Returns the JWT as a string representing an authentication token for the provided subject, with timing claims adjusted according to signedInAgoMs if given.

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

Asynchronously performs a delete operation using the provided token.

The function is intended to carry out a deletion-related action (e.g., an API call) that requires the given token.

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

D is a function that takes a single numeric argument n.

The specific behavior or side effects of the function are not specified in the provided signature.


The signature does not indicate what the function returns, so the return value is not specified.

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
