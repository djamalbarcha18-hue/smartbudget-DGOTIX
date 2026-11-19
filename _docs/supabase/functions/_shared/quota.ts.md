<!-- METADATA: {"source_path": "supabase/functions/_shared/quota.ts", "source_sha": "0afe9e7369a0f9c6f02b84ac661035816be7ac2a", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T21:41:34Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/functions/_shared/quota.ts",
  "source_hash": "a10cfe588d86558e76ca36b30183cc2b87df7e92f598f3ef38a345ac172655e9",
  "last_updated": "2026-11-19T21:40:53.474940+00:00",
  "git_sha": "0afe9e7369a0f9c6f02b84ac661035816be7ac2a",
  "tokens_used": 7447,
  "complexity_score": 4,
  "estimated_review_time_minutes": 15,
  "external_dependencies": []
}
```

</details>

[Documentation Home](../../../README.md) > [supabase](../../README.md) > [functions](../README.md) > [_shared](./README.md) > **quota**

---

# quota.ts

> **File:** `supabase/functions/_shared/quota.ts`

![Complexity: Medium](https://img.shields.io/badge/Complexity-Medium-yellow) ![Review Time: 15min](https://img.shields.io/badge/Review_Time-15min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This module centralizes quota and allowance logic used by the application to determine usage limits for AI answers and OCR scans. It defines typed plan identifiers and window types, concrete allowance records for free and pro plans, trial-specific allowances and cost ceilings, and daily limits based on an account's trust level. The module exposes a set of utility functions to coerce stored plan values, compute an account's effective plan (including a beta override), detect trial status, compute plan or trial allowances for different usage kinds, and produce a QuotaInfo structure that represents what the app shows the user about their allowance.

The file groups related constants and small helpers so callers can reason about lifetime vs monthly windows, per-plan limits, trial fallbacks, new-account reductions, and monthly AI cost ceilings. It also includes helpers to compute reduced allowances for new accounts and to express trust tiers such as paid, established, or new, and how those tiers map to daily usage caps.

## Dependencies

No dependencies identified.

## 📁 Directory

This file is part of the **_shared** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- Uses TypeScript union types to represent fixed categories (Plan, QuotaWindow, UsageKind, Trust).
- Encodes plan-specific configuration as Record keyed by Plan for straightforward lookup (AI_QUOTA, OCR_QUOTA, AI_MONTHLY_COST_CEILING_USD).
- Separates concerns into small focused functions that normalize input, determine context (beta/trial/new account), and compute derived allowances.

## Maintenance Notes

- Define plan and quota window types and provide concrete allowance records for AI and OCR quotas per plan (AI_QUOTA, OCR_QUOTA).
- Provide trial-specific constants and behavior (TRIAL_AI_QUOTA, TRIAL_OCR_QUOTA, TRIAL_AI_COST_CEILING_USD) and detect when an account is on trial (onTrial, trialAllowance).
- Coerce and resolve a user's plan and environment-level overrides (normalizePlan, effectivePlan, betaAllAccess).
- Compute allowances and limits for usage kinds, including reductions for new accounts and trust-based daily caps (allowanceFor, newAccountDays, TRUST, DAILY_LIMIT, NEW_ACCOUNT_QUOTA).
- Expose a final representation of an account's quota for the UI (QuotaInfo, quotaInfo) and helper accessors for per-feature ceilings (aiAllowance, ocrAllowance, aiCostCeiling).


---

## Constants and Types

| Name | Type | Value |
| --- | --- | --- |
| `Plan` | type alias | `"free" \| "pro"` |
| `QuotaWindow` | type alias | `"lifetime" \| "monthly"` |
| `AI_QUOTA` | `Record<Plan, Allowance>` | `{…}` |
| `OCR_QUOTA` | `Record<Plan, Allowance>` | `{…}` |
| `AI_MONTHLY_COST_CEILING_USD` | `Record<Plan, number>` | `{…}` |
| `TRIAL_AI_QUOTA` | `Allowance` | `{ limit: 5, window: "monthly" }` |
| `TRIAL_OCR_QUOTA` | `Allowance` | `{ limit: 5, window: "monthly" }` |
| `TRIAL_AI_COST_CEILING_USD` | — | `0.3` |
| `UsageKind` | type alias | `"ai" \| "ocr"` |
| `Trust` | type alias | `"paid" \| "established" \| "new"` |
| `NEW_ACCOUNT_QUOTA` | `Record<UsageKind, number>` | `{ ai: 10, ocr: 5 }` |
| `DAILY_LIMIT` | `Record<Trust, Record<UsageKind, number>>` | `{…}` |



---

## Functions and Classes


### Allowance

![Type: Abstract](https://img.shields.io/badge/Type-Abstract-purple) ![Attributes: 3](https://img.shields.io/badge/Attributes-3-blue)

#### Description

Represents a single quota allowance that defines how many actions are permitted within a given time window.

Acts as the primary data model for quota/allowance configuration in the module, supplying structured information about limits and timing that other quota-management logic can use to enforce or evaluate usage.

Responsibilities:
- Define the maximum number of allowed units or actions via the numeric limit.
- Specify the time span over which the limit applies using the QuotaWindow object.
- Provide an offset value to shift or align the start of the quota window as needed.
- Serve as a typed container for quota configuration consumed by other parts of the module.

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `limit` (class) | `number` | 🔓 public | Class attribute limit |
| `window` (class) | `QuotaWindow` | 🔓 public | Class attribute window |
| `offset` (class) | `number` | 🔓 public | Class attribute offset |

---



### normalizePlan

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def normalizePlan(p: unknown) -> Plan:
```

#### Description

Normalize an arbitrary/possibly invalid stored plan value to a safe default (FREE).

It also maps the retired "basic" plan to PRO so that databases not yet migrated do not inadvertently change customers' plans.


p is the unknown value to be coerced/validated (for example, a plan value read from the database) and will be inspected and converted to a known Plan variant.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `p` | `unknown` | ✅ | — |

#### Returns

**Type:** `Plan`

—

#### Complexity

Not analyzed

---



### betaAllAccess

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def betaAllAccess() -> boolean:
```

#### Description

Determines whether the application is running in a beta mode that grants every signed-in user PRO limits.

It checks an Edge Function secret and only enables the global PRO access when that secret is exactly the string "true"; any missing, incorrect, or unreadable secret keeps paid-plan limits (fails closed).

#### Returns

**Type:** `boolean`

—

#### Complexity

Not analyzed

---



### effectivePlan

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def effectivePlan(plan: Plan, trialPlan: Plan | null, trialExpiresAt: string | null, now: Date = new Date()) -> Plan:
```

#### Description

Determine which subscription plan should be considered active right now by choosing between the base plan and a trial plan if the trial is currently valid.

It compares the present time to the trial expiration and returns the trial plan when it is still in effect, otherwise the regular plan.


trialPlan is an optional temporary Plan to use during a trial period; trialExpiresAt is an optional ISO timestamp string indicating when that trial ends; now is the reference Date (defaults to the current time) used to decide if the trial is still active.

Returns the Plan that is presently effective (the trialPlan if it's active at 'now', otherwise the provided base plan).

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `plan` | `Plan` | ✅ | — |
| `trialPlan` | `Plan | null` | ✅ | — |
| `trialExpiresAt` | `string | null` | ✅ | — |
| `now` = `new Date()` | `Date` | ❌ | — |

#### Returns

**Type:** `Plan`

Returns the Plan that is presently effective (the trialPlan if it's active at 'now', otherwise the provided base plan).

#### Complexity

Not analyzed

---



### onTrial

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def onTrial(plan: Plan, paidPlan: Plan, beta: boolean = betaAllAccess()) -> boolean:
```

#### Description

Determines whether the account is exceeding the features or limits of the plan it actually pays for because it is on a trial (as opposed to having purchased an upgrade or relying on beta access).

The optional beta flag lets callers treat beta access as separate when making that determination.


plan and paidPlan are the current effective plan and the plan the account actually pays for; beta is an override (defaults to betaAllAccess()) used mainly by tests to control whether beta access counts.

Returns true if the account is above its paid plan due to being on a trial (and not due to a purchase or beta access); otherwise returns false.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `plan` | `Plan` | ✅ | — |
| `paidPlan` | `Plan` | ✅ | — |
| `beta` = `betaAllAccess()` | `boolean` | ❌ | — |

#### Returns

**Type:** `boolean`

Returns true if the account is above its paid plan due to being on a trial (and not due to a purchase or beta access); otherwise returns false.

#### Complexity

Not analyzed

---



### trialAllowance

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def trialAllowance(quota: Allowance, base: number | null) -> Allowance:
```

#### Description

Compute an allowance object representing a trial's usage allowance anchored to the trial start.

If the account's all-time usage at trial start is provided, the allowance is calculated relative to that base; otherwise the allowance is computed using the calendar month behavior.


quota is the Allowance to be adjusted for the trial; base is the account's all-time usage value at the moment the trial began (a number) or null if that starting usage wasn't recorded, in which case the function falls back to calendar-month counting.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `quota` | `Allowance` | ✅ | — |
| `base` | `number | null` | ✅ | — |

#### Returns

**Type:** `Allowance`

—

#### Complexity

Not analyzed

---



### aiAllowance

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def aiAllowance(plan: Plan, paidPlan: Plan, beta: boolean = betaAllAccess(), trialBase: number | null = null) -> Allowance:
```

#### Description

Determine how many AI answers are allowed for a user by returning either the allowance associated with their current plan or a small trial allowance when they are on a trial.

It uses the provided plan information and optional beta/trial parameters to choose the appropriate allowance.


beta toggles beta-specific behavior (defaults to the result of betaAllAccess()), and trialBase is an optional numeric base used when computing a trial allowance (see trialAllowance). The plan and paidPlan inputs are the current and paid plan details used to decide which allowance applies.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `plan` | `Plan` | ✅ | — |
| `paidPlan` | `Plan` | ✅ | — |
| `beta` = `betaAllAccess()` | `boolean` | ❌ | — |
| `trialBase` = `null` | `number | null` | ❌ | — |

#### Returns

**Type:** `Allowance`

—

#### Complexity

Not analyzed

---



### ocrAllowance

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def ocrAllowance(plan: Plan, paidPlan: Plan, beta: boolean = betaAllAccess(), trialBase: number | null = null) -> Allowance:
```

#### Description

Determines the number of cloud OCR scans allowed: it returns the plan's normal allowance, or if the user is on a trial it returns a small trial allowance (controlled by trialBase).

plan and paidPlan are the current and paid plan descriptors; beta is a boolean flag (defaults to betaAllAccess()) that can alter allowance behavior for beta users; trialBase is an optional numeric base used to compute the trial-specific allowance.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `plan` | `Plan` | ✅ | — |
| `paidPlan` | `Plan` | ✅ | — |
| `beta` = `betaAllAccess()` | `boolean` | ❌ | — |
| `trialBase` = `null` | `number | null` | ❌ | — |

#### Returns

**Type:** `Allowance`

—

#### Complexity

Not analyzed

---



### aiCostCeiling

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def aiCostCeiling(plan: Plan, paidPlan: Plan, beta: boolean = betaAllAccess()) -> number:
```

#### Description

Calculate the monthly AI cost guard for an account: it returns the ceiling based on the provided plan, or a lower ceiling when the account is on a trial relative to the paid plan.

The beta flag alters behavior when beta features (all-access) are enabled.


plan and paidPlan are the current plan and the paid plan to compare against; beta is a boolean that toggles alternate logic when beta/all-access features are enabled.

Returns a numeric value representing the monthly AI cost ceiling to be applied.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `plan` | `Plan` | ✅ | — |
| `paidPlan` | `Plan` | ✅ | — |
| `beta` = `betaAllAccess()` | `boolean` | ❌ | — |

#### Returns

**Type:** `number`

Returns a numeric value representing the monthly AI cost ceiling to be applied.

#### Complexity

Not analyzed

---



### newAccountDays

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def newAccountDays() -> number:
```

#### Description

Returns the threshold in days used to determine whether an account is considered "new".

This value corresponds to a secret named NEW_ACCOUNT_DAYS and is used to classify accounts younger than that many days as new.

#### Returns

**Type:** `number`

—

#### Complexity

Not analyzed

---



### trustOf

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def trustOf(paidPlan: Plan, account: { createdAt: string | null; emailConfirmed: boolean }, now: Date = new Date()) -> Trust:
```

#### Description

Determines the Trust level for an account based on the provided paid plan and account metadata (account creation time and whether the email is confirmed), using the optional reference time 'now' when evaluating temporal conditions.

It encapsulates the logic that maps plan and account state into a Trust value.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `paidPlan` | `Plan` | ✅ | — |
| `account` | `{ createdAt: string | null; emailConfirmed: boolean }` | ✅ | — |
| `now` = `new Date()` | `Date` | ❌ | — |

#### Returns

**Type:** `Trust`

—

#### Complexity

Not analyzed

---



### allowanceFor

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def allowanceFor(base: Allowance, kind: UsageKind, trust: Trust) -> Allowance:
```

#### Description

Compute the plan allowance adjusted downwards for a new account.

In other words, take a base allowance and return a modified allowance appropriate for the given usage kind and trust level, applying any reductions that apply to new accounts.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `base` | `Allowance` | ✅ | — |
| `kind` | `UsageKind` | ✅ | — |
| `trust` | `Trust` | ✅ | — |

#### Returns

**Type:** `Allowance`

—

#### Complexity

Not analyzed

---



### QuotaInfo

![Type: Abstract](https://img.shields.io/badge/Type-Abstract-purple) ![Attributes: 5](https://img.shields.io/badge/Attributes-5-blue)

#### Description

Represents the computed usage allowance information that the application displays to a user.

Within supabase/functions/_shared/quota.ts this interface defines the shape of quota information exchanged between server and client code. It standardizes how allowance data is represented across the module so other parts can rely on a consistent structure.

Responsibilities:
- Expose the numeric quota limit, amount used, and remaining allowance so UI and business logic can present current consumption.
- Identify the quota window type or period via the window field to indicate the scope of the allowance.
- Provide the resetsAt timestamp (or null) to allow the client to show when the quota will next be refreshed.
- Serve as the canonical DTO for server-computed allowance data passed to client-side code.

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `limit` (class) | `number` | 🔓 public | Class attribute limit |
| `used` (class) | `number` | 🔓 public | Class attribute used |
| `remaining` (class) | `number` | 🔓 public | Class attribute remaining |
| `window` (class) | `QuotaWindow` | 🔓 public | Class attribute window |
| `resetsAt` (class) | `string | null` | 🔓 public | Class attribute resetsAt |

---



### quotaInfo

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def quotaInfo(allow: Allowance, used: number, now: Date = new Date()) -> QuotaInfo:
```

#### Description

Compute and return quota-related information for a given allowance and amount used at a specific time.

It evaluates the provided allowance together with the used value (and optional current time) to produce a QuotaInfo summary.


allow is an Allowance object describing the quota rules/limits; used is the numeric amount consumed against that allowance; now is an optional Date (defaults to the current time) used when computing time-sensitive quota fields.

Returns a QuotaInfo object that summarizes the allowance, usage, and any derived quota state (e.g., remaining amount or period-based calculations).

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `allow` | `Allowance` | ✅ | — |
| `used` | `number` | ✅ | — |
| `now` = `new Date()` | `Date` | ❌ | — |

#### Returns

**Type:** `QuotaInfo`

Returns a QuotaInfo object that summarizes the allowance, usage, and any derived quota state (e.g., remaining amount or period-based calculations).

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
