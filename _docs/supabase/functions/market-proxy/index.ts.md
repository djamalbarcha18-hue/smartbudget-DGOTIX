<!-- METADATA: {"source_path": "supabase/functions/market-proxy/index.ts", "source_sha": "7a8a35ae1d49bdd07161c1092f8a54bb1f83ec9e", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T11:21:15Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/functions/market-proxy/index.ts",
  "source_hash": "20135ba1bafb341109eb631393bb7e8a1f5a541702e1069790c75b64049816f7",
  "last_updated": "2026-11-19T11:20:37.660613+00:00",
  "git_sha": "7a8a35ae1d49bdd07161c1092f8a54bb1f83ec9e",
  "tokens_used": 2634,
  "complexity_score": 2,
  "estimated_review_time_minutes": 11,
  "external_dependencies": []
}
```

</details>

[Documentation Home](../../../README.md) > [supabase](../../README.md) > [functions](../README.md) > [market-proxy](./README.md) > **index**

---

# index.ts

> **File:** `supabase/functions/market-proxy/index.ts`

![Complexity: Low](https://img.shields.io/badge/Complexity-Low-green) ![Review Time: 11min](https://img.shields.io/badge/Review_Time-11min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This TypeScript module implements a small set of HTTP helper and proxy endpoints intended to support market-related requests in a Supabase Edge Function. It exposes an unavailable responder, a proxy to a metal price API, an async provider of free data sources (notably IMF monthly averages), and a CORS helper; the metalPriceApi and freeSources functions are asynchronous to accommodate network calls or I/O. The file is organized as independent module-level functions so each exported operation can be used directly by the edge runtime or composed by other handlers.

## Dependencies

No dependencies identified.

## 📁 Directory

This file is part of the **market-proxy** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- exports multiple module-level functions rather than classes
- implements async handlers for I/O-bound operations (metalPriceApi, freeSources)
- includes a dedicated CORS helper function to centralize cross-origin response behavior

## Maintenance Notes

- Return a standardized unavailable response for requests that cannot be serviced (unavailable).
- Proxy requests to an external metal price API (metalPriceApi) using an asynchronous handler suitable for network I/O.
- Provide information about free data sources, including IMF monthly averages, via an asynchronous freeSources function.
- Apply Cross-Origin Resource Sharing handling for requests using a cors helper function.


---

## Functions and Classes


### unavailable

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def unavailable(specs: Spec[], source="requires data source") -> Quote[]:
```

#### Description

Generate and return an array of Quote objects based on an input list of Spec entries, using an optional source string (defaulting to "requires data source").

The function maps the provided specs to one or more Quote results.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `specs` | `Spec[]` | ✅ | — |
| `source` = `"requires data source"` | `Unknown` | ❌ | — |

#### Returns

**Type:** `Quote[]`

—

#### Complexity

Not analyzed

---



### metalPriceApi

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def metalPriceApi(_category, specs) -> Adapter:
```

#### Description

Handles a request for metal price data within the market-proxy function, using the provided category and specification options to build and return an adapter that exposes a symbols nested function.

It prepares and configures the adapter logic needed to serve metal pricing information based on the given specs.


_category selects or identifies the high-level category of the request (not otherwise used directly in the signature) and specs contains options and configuration describing which metal symbols, exchanges, timeframes, or formatting the adapter should support. The specs object drives how the internal symbols nested function and other adapter behavior operate.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `_category` | `Unknown` | ✅ | — |
| `specs` | `Unknown` | ✅ | — |

#### Returns

**Type:** `Adapter`

—

#### Complexity

Not analyzed

---



### symbols

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def symbols(s):
```

#### Description

Provides functionality related to market symbols within the market-proxy function module.

It performs an operation (such as retrieving, formatting, or proxying) based on the supplied input to produce symbol-related output.


s is the single input to the function; its name is not descriptive, so it represents the query, context, or configuration used to determine which symbols or symbol-related data to process and return.

Returns symbol-related data (for example a list or payload of market symbols or a proxied response containing symbol information) based on the provided input.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `s` | `Unknown` | ✅ | — |

#### Complexity

Not analyzed

---



### freeSources

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def freeSources(category, specs) -> Adapter:
```

#### Description

Provides a data adapter that yields free data sources: it prefers IMF monthly averages (keyless) for all covered series and, for energy prices, uses the EIA daily prices first when an EIA_API_KEY is present.

If a source fails, its codes are passed to the next available source and any remaining series become unavailable.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `category` | `Unknown` | ✅ | — |
| `specs` | `Unknown` | ✅ | — |

#### Returns

**Type:** `Adapter`

—

#### Complexity

Not analyzed

---



### cors

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def cors() -> HeadersInit:
```

#### Description

Provides a preconfigured set of HTTP CORS headers for the market-proxy function so they can be applied to responses or requests.

It centralizes the Cross-Origin Resource Sharing header values into a HeadersInit object for consistent use across the function.

#### Returns

**Type:** `HeadersInit`

—

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
