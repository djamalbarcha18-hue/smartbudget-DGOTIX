<!-- METADATA: {"source_path": "supabase/functions/_shared/paypal.ts", "source_sha": "5ae9b3c92df4956034846086a531d52049d3c732", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T11:21:15Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/functions/_shared/paypal.ts",
  "source_hash": "2a78955c1dd29c72f96d4e15aae98cf33c455c157fff7afb09049e769a06e8c6",
  "last_updated": "2026-11-19T11:20:42.846874+00:00",
  "git_sha": "5ae9b3c92df4956034846086a531d52049d3c732",
  "tokens_used": 3965,
  "complexity_score": 1,
  "estimated_review_time_minutes": 8,
  "external_dependencies": []
}
```

</details>

[Documentation Home](../../../README.md) > [supabase](../../README.md) > [functions](../README.md) > [_shared](./README.md) > **paypal**

---

# paypal.ts

> **File:** `supabase/functions/_shared/paypal.ts`

![Complexity: Low](https://img.shields.io/badge/Complexity-Low-green) ![Review Time: 8min](https://img.shields.io/badge/Review_Time-8min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This module provides shared PayPal integration utilities used by server-side functions. It centralizes PayPal configuration and HTTP interactions: determining the API base URL, confirming configuration is present, computing token reuse lifetime, obtaining an OAuth2 client-credentials access token, and performing a lightweight local check of PayPal signature headers. The module also exposes higher-level operations for creating subscriptions (returning the approval URL for user redirection), verifying webhook signatures using PayPal's verify-webhook-signature API, and looking up a captured payment (sale) to extract the associated subscription and amount.

All network-facing operations that interact with PayPal’s APIs are implemented as async functions. The file separates simple helpers (base URL, configuration check, token lifetime calculation, and a plausibility check for headers) from operations that perform remote calls (token fetch, subscription creation, webhook verification, and sale retrieval), so callers can compose these primitives as needed for webhooks and subscription flows.

## Dependencies

No dependencies identified.

## 📁 Directory

This file is part of the **_shared** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- uses async functions for all network interactions
- centralizes PayPal API interactions and credential handling
- separates lightweight local checks from remote verification calls
- implements token lifetime calculation to avoid using expired tokens

## Maintenance Notes

- Provide PayPal API base URL and a check that required PayPal configuration is present.
- Calculate how long an acquired OAuth2 access token can be safely reused.
- Acquire an OAuth2 client-credentials access token from PayPal for authenticated API calls.
- Perform a local plausibility check of PayPal signature headers before attempting verification.
- Create subscriptions (returning the approval redirect URL), verify webhook signatures via PayPal, and fetch details of captured payments (sales).


---

## Functions and Classes


### paypalApiBase

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def paypalApiBase() -> string:
```

#### Description

Provides the base PayPal API URL as a string.

The function likely centralizes the PayPal API base endpoint used by other helpers in the shared PayPal module.

#### Returns

**Type:** `string`

—

#### Complexity

Not analyzed

---



### paypalConfigured

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def paypalConfigured() -> boolean:
```

#### Description

Checks whether PayPal has been configured for the application.

It returns a boolean indicating if the necessary PayPal configuration or credentials are present and available for use.

#### Returns

**Type:** `boolean`

—

#### Complexity

Not analyzed

---



### tokenLifetimeS

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def tokenLifetimeS(expiresIn: unknown) -> number:
```

#### Description

Compute how many seconds a PayPal access token should be reused for by taking the token's expires_in value and subtracting one minute.

If the input is invalid or results in a non-positive value, it returns 0.


expiresIn is an unknown value expected to represent PayPal's expires_in (typically a numeric value of seconds); the function will parse or coerce this value to determine the lifetime in seconds.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `expiresIn` | `unknown` | ✅ | — |

#### Returns

**Type:** `number`

—

#### Complexity

Not analyzed

---



### paypalAccessToken

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def paypalAccessToken(now: number = Date.now()) -> Promise<string>:
```

#### Description

Fetches an OAuth2 access token using the client-credentials flow and returns it as a string.

If the token cannot be obtained the function will throw an error.


now is an optional numeric timestamp (milliseconds since epoch) representing the current time used internally by the function; it defaults to Date.now().

Returns a Promise that resolves to the access token string.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `now` = `Date.now()` | `number` | ❌ | — |

#### Returns

**Type:** `Promise<string>`

Returns a Promise that resolves to the access token string.

#### Complexity

Not analyzed

---



### plausiblePaypalSignature

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def plausiblePaypalSignature(headers: Headers) -> boolean:
```

#### Description

Performs a lightweight, local validation of PayPal-specific HTTP signature headers by checking that the signing algorithm and the certificate URL come from PayPal's expected values.

It acts as an early filter that rejects requests which clearly do not originate from PayPal so the system can avoid making an external verify call.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `headers` | `Headers` | ✅ | — |

#### Returns

**Type:** `boolean`

—

#### Complexity

Not analyzed

---



### createPaypalSubscription

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def createPaypalSubscription(token: string, planId: string, userId: string, returnUrl: string = undefined, cancelUrl: string = undefined) -> Promise<string | null>:
```

#### Description

Creates a PayPal subscription for a given billing plan and returns the approval URL the user must visit to approve the subscription.

The function attaches the provided userId as custom_id so the user can be identified in PayPal webhooks and returns null if no approval URL is available.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `token` | `string` | ✅ | — |
| `planId` | `string` | ✅ | — |
| `userId` | `string` | ✅ | — |
| `returnUrl` = `undefined` | `string` | ❌ | — |
| `cancelUrl` = `undefined` | `string` | ❌ | — |

#### Returns

**Type:** `Promise<string | null>`

—

#### Complexity

Not analyzed

---



### verifyPaypalWebhook

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def verifyPaypalWebhook(token: string, headers: Headers, webhookId: string, event: unknown) -> Promise<boolean>:
```

#### Description

Sends PayPal's verify-webhook-signature request to validate that an incoming webhook event was genuinely sent by PayPal.

It uses the provided transmission headers, the configured webhook ID, the parsed event payload, and an access token to perform the verification and returns whether the signature is valid.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `token` | `string` | ✅ | — |
| `headers` | `Headers` | ✅ | — |
| `webhookId` | `string` | ✅ | — |
| `event` | `unknown` | ✅ | — |

#### Returns

**Type:** `Promise<boolean>`

—

#### Complexity

Not analyzed

---



### paypalSale

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def paypalSale(token: string, saleId: string) -> Promise<:
```

#### Description

Fetches details for a captured PayPal payment (a sale) identified by saleId using the provided authorization token.

It returns the sale's associated subscription and amount information, or throws an error if the sale cannot be retrieved.


Resolves to an object representing the captured payment (sale) containing at least the subscription reference and the amount charged; throws on failure.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `token` | `string` | ✅ | — |
| `saleId` | `string` | ✅ | — |

#### Returns

**Type:** `Promise<`

Resolves to an object representing the captured payment (sale) containing at least the subscription reference and the amount charged; throws on failure.

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
