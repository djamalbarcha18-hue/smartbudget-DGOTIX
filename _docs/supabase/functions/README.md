[Documentation Home](../../README.md) > [supabase](../README.md) > [functions](./README.md) > **functions**

---

# 📁 functions

> **Purpose:** Collect and host Supabase serverless Edge Function implementations and shared server-side utilities used for billing, payments (PayPal), quota/allowance logic, and HTTP proxying within the project.
> 

![Organization: Feature Based](https://img.shields.io/badge/Organization-Feature_Based-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Subdirectories](#subdirectories)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)

---

## Overview

This directory groups Supabase Edge Function implementations and shared server-side utilities that back server-side behaviors such as account deletion checks, payment webhook handling, proxy endpoints, and an AI gateway helper surface. At the root level the directory is organized into focused subdirectories each containing one or more TypeScript modules that implement a single function or a small set of helper types and routines. The documented root-level modules implement account deletion logic, market-related proxy endpoints, a parallel-proxy helper surface, a PayPal webhook handler, and utilities for an AI gateway.

A dedicated _shared subdirectory centralizes reusable server-side utilities consumed across multiple functions: PayPal integration helpers (including a paypal.ts implementation and associated paypal_test.ts unit tests), quota/allowance logic for usage limits, and other runtime helpers. Together the function-specific modules depend on these shared utilities where appropriate; for example the PayPal webhook handler and billing-related functions reference PayPal utilities and quota logic to validate and process incoming events. This directory is a feature-aligned consolidation of serverless handlers and the common code they share, forming the serverless function layer for billing, payments, and auxiliary HTTP endpoints in the larger system.


### File Organization

Functions are grouped by feature or runtime role in separate subdirectories. Each subdirectory contains the implementation(s) relevant to that feature: a single Edge Function entrypoint or a small collection of helper types. Shared reusable utilities and tests live under the _shared subdirectory so multiple functions can import common logic (e.g., PayPal handling, quota/allowance helpers). Additional related function groups (billing-config, coupon-validate, create-checkout, manage-subscription, receipt-scan, whop-webhook) are present as their own subdirectories and are referenced in the repository for related billing/payment flows.

## 📂 Subdirectories

This directory contains the following subdirectories:

### [📁 _shared](./_shared/README.md)

**Purpose:** Provide shared server-side utilities for payments (PayPal), quota/allowance logic, and other runtime helpers consumed by multiple serverless functions.

![Files: 3](https://img.shields.io/badge/Files-3-blue)

---

### [📁 ai-gateway](./ai-gateway/README.md)

**Purpose:** Contains utility routines used by an AI gateway function running in a Supabase environment to support the function's internal logic and interactions.

![Files: 1](https://img.shields.io/badge/Files-1-blue)

---

### [📁 delete-account](./delete-account/README.md)

**Purpose:** Contains a Supabase Edge Function implementation that handles account deletion checks and billing-related considerations for user accounts.

![Files: 1](https://img.shields.io/badge/Files-1-blue)

---

### [📁 market-proxy](./market-proxy/README.md)

**Purpose:** Implements HTTP helper and proxy endpoints as a Supabase Edge Function to support market-related requests.

![Files: 1](https://img.shields.io/badge/Files-1-blue)

---

### [📁 parallel-proxy](./parallel-proxy/README.md)

**Purpose:** Holds shared TypeScript types and utility functions used by the parallel-proxy serverless function implementation in the Supabase functions collection.

![Files: 1](https://img.shields.io/badge/Files-1-blue)

---

### [📁 paypal-webhook](./paypal-webhook/README.md)

**Purpose:** Contains the implementation of a PayPal webhook endpoint and helpers to verify, process, and respond to incoming PayPal events for server-side handling.

![Files: 1](https://img.shields.io/badge/Files-1-blue)

---
## Dependencies

### External Dependencies

| Dependency | Usage |
| --- | --- |
| `PayPal API` | Used conceptually by the PayPal integration utilities to verify webhook signatures and process PayPal event payloads (implementation details live in _shared/paypal.ts and are exercised by paypal-webhook/index.ts). |

### Internal Dependencies

| Dependency | Usage |
| --- | --- |
| `_shared utilities` | Centralized runtime helpers for PayPal integration, quota/allowance logic, and other functions; consumed by webhook handlers and other Edge Function modules. |

## Architecture Notes

- Shared cross-function utilities are centralized under _shared to avoid duplication and ensure consistent payment and quota logic across all serverless handlers.
- Each feature or function gets its own subdirectory with a single entrypoint (index.ts) to keep deployment units small and focused, simplifying testing and maintenance.

---

## Navigation

**↑ Parent Directory:** [Go up](../README.md)
**🔗 Related:** [_shared](./_shared/README.md) • [ai-gateway](./ai-gateway/README.md) • [delete-account](./delete-account/README.md) • [market-proxy](./market-proxy/README.md) • [parallel-proxy](./parallel-proxy/README.md)

---

*Generated by Woden Docbot*