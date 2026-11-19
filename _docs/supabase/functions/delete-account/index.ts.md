<!-- METADATA: {"source_path": "supabase/functions/delete-account/index.ts", "source_sha": "898f3856937f8263303f76d652222c450e369e3e", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T21:41:34Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/functions/delete-account/index.ts",
  "source_hash": "4e8af0846a2d221119faea7b184ab8daf747d9c730bccd1bfd29b376eb5b06cb",
  "last_updated": "2026-11-19T21:40:29.748453+00:00",
  "git_sha": "898f3856937f8263303f76d652222c450e369e3e",
  "tokens_used": 2189,
  "complexity_score": 1,
  "estimated_review_time_minutes": 6,
  "external_dependencies": []
}
```

</details>

[Documentation Home](../../../README.md) > [supabase](../../README.md) > [functions](../README.md) > [delete-account](./README.md) > **index**

---

# index.ts

> **File:** `supabase/functions/delete-account/index.ts`

![Complexity: Low](https://img.shields.io/badge/Complexity-Low-green) ![Review Time: 6min](https://img.shields.io/badge/Review_Time-6min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This module implements a Supabase Edge Function for handling account deletion related checks and billing considerations. It defines a SubRow interface representing subscription state (active, trialing, past due, and not set to end) and exposes two module-level utility functions: lastSignInMs, which derives the caller's last sign-in time from the verified session JWT's amr claim, and bills, which performs billing-related logic before account deletion. The file also declares a REAUTH_WINDOW_MS constant (15 minutes) used to control a reauthentication window for sensitive operations.

The implementation integrates shared helpers for CORS and JSON responses, authentication (including requireUserId and service client access), and usage rate limiting, indicating this code is intended to run as a protected, rate-limited HTTP handler that enforces recent reauthentication and inspects subscription status before proceeding with account deletion actions.

## Dependencies

### Internal Dependencies

| Module | Usage |
| --- | --- |
| `../_shared/cors.ts` | import { corsHeaders, jsonResponse } from "../_shared/cors.ts"; |
| `../_shared/auth.ts` | import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts"; |
| `../_shared/usage.ts` | import { rateLimited } from "../_shared/usage.ts"; |

## 📁 Directory

This file is part of the **delete-account** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- Defines a small set of focused utility functions for authentication and billing checks (lastSignInMs, bills).
- Uses a dedicated subscription-shaped interface (SubRow) to model billing state.
- Integrates cross-cutting helpers for CORS, JSON responses, authentication, and rate limiting (corsHeaders, jsonResponse, requireUserId, serviceClient, rateLimited).
- Declares a time-window constant (REAUTH_WINDOW_MS) to centralize reauthentication policy.

## Maintenance Notes

- Represent subscription state relevant to deletion decisions via the SubRow interface.
- Determine when the caller last signed in by extracting the amr value from a verified session JWT through lastSignInMs.
- Perform billing and subscription checks required for account deletion flows in the bills function.
- Enforce a reauthentication window using the REAUTH_WINDOW_MS constant to ensure recent authentication for sensitive operations.


---

## Constants

| Name | Type | Value |
| --- | --- | --- |
| `REAUTH_WINDOW_MS` | — | `15 * 60 * 1000` |



---

## Functions and Classes


### lastSignInMs

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def lastSignInMs(req: Request) -> number | null:
```

#### Description

Extracts the time of the caller's last sign-in from a verified session JWT by reading the `amr` claim, where Supabase records each sign-in method with its timestamp.

If the token does not include that claim, the function returns null.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `req` | `Request` | ✅ | — |

#### Returns

**Type:** `number | null`

—

#### Complexity

Not analyzed

---



### SubRow

![Type: Abstract](https://img.shields.io/badge/Type-Abstract-purple) ![Attributes: 3](https://img.shields.io/badge/Attributes-3-blue)

#### Description

Represents a subscription row that indicates a customer is still being billed.

Acts as a typed data structure within the delete-account function file to represent subscriptions that are still being billed, enabling other parts of the module to make decisions based on plan, status, and cancellation scheduling.

Responsibilities:
- Hold the subscription plan identifier (plan) for identification of the product or tier.
- Convey the subscription billing status (status) when available, allowing null when status is not provided.
- Indicate whether the subscription is scheduled to cancel at the end of the current billing period (cancel_at_period_end), allowing null when unknown.
- Serve as a simple data container for subscription-related checks elsewhere in the module (e.g., to determine ongoing billing).

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `plan` (class) | `string` | 🔓 public | Class attribute plan |
| `status` (class) | `string | null` | 🔓 public | Class attribute status |
| `cancel_at_period_end` (class) | `boolean | null` | 🔓 public | Class attribute cancel_at_period_end |

---



### bills

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def bills(row: SubRow | null | undefined) -> boolean:
```

#### Description

Evaluates the provided SubRow (which may be null or undefined) and produces a boolean result based on that input.

The function encapsulates a check or predicate concerning the subscription row named 'row'.


row is a SubRow object or null/undefined; the function examines this input to determine the boolean outcome.

Returns a boolean indicating the result of the evaluation or predicate applied to the supplied row.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `row` | `SubRow | null | undefined` | ✅ | — |

#### Returns

**Type:** `boolean`

Returns a boolean indicating the result of the evaluation or predicate applied to the supplied row.

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
