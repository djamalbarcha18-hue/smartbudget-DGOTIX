<!-- METADATA: {"source_path": "supabase/functions/_shared/ai/gateway.ts", "source_sha": "25e3433a93d28f9471d0bf99b1b9c07c931d457a", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T11:21:15Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/functions/_shared/ai/gateway.ts",
  "source_hash": "22af5985b15014ea475557ae8ef259d33d7f16380d68bb9e8ed016587ab71df8",
  "last_updated": "2026-11-19T11:21:15.978756+00:00",
  "git_sha": "25e3433a93d28f9471d0bf99b1b9c07c931d457a",
  "tokens_used": 9695,
  "complexity_score": 6,
  "estimated_review_time_minutes": 24,
  "external_dependencies": [
    "npm:@supabase/supabase-js@2.117.2"
  ]
}
```

</details>

[Documentation Home](../../../../README.md) > [supabase](../../../README.md) > [functions](../../README.md) > [_shared](../README.md) > [ai](./README.md) > **gateway**

---

# gateway.ts

> **File:** `supabase/functions/_shared/ai/gateway.ts`

![Complexity: Medium](https://img.shields.io/badge/Complexity-Medium-yellow) ![Review Time: 24min](https://img.shields.io/badge/Review_Time-24min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This module implements a gateway layer that selects and invokes AI model providers for different task types. It defines types and interfaces for providers, models, configuration, classification results, and generation results, and it includes logic to load owner-specific configuration from a Supabase database, determine effective models and candidate providers for tasks, classify requests, estimate costs, and dispatch generation requests to provider-specific implementations (Google Gemini, OpenAI, Anthropic). The file also records success and failure metrics for requests and exposes utilities for checking provider availability and posting requests to provider endpoints.

## Dependencies

### External Dependencies

| Module | Usage |
| --- | --- |
| `npm:@supabase/supabase-js@2.117.2` | import { type SupabaseClient } from "npm:@supabase/supabase-js@2.117.2"; |

### Internal Dependencies

| Module | Usage |
| --- | --- |
| `./budget.ts` | import { MAX_OUTPUT_TOKENS } from "./budget.ts"; |

## 📁 Directory

This file is part of the **ai** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- Extensive use of TypeScript interfaces to represent domain entities (ModelDef, GatewayConfig, Classified, Breaker, GenResult).
- Asynchronous operations for IO-bound work such as loadConfig, generate, and provider-specific generation functions.
- Provider-specific implementations exposed alongside a generic dispatch (geminiGen, openaiGen, anthropicGen and generate/post).
- A custom ProviderError class to represent provider-related exceptions separate from generic errors.

## Maintenance Notes

- Define shared types and interfaces used across the AI gateway such as ModelDef, GatewayConfig, Classified, Breaker, and GenResult.
- Load owner-specific gateway configuration from the Supabase database with loadConfig and compute effective model overlays via effectiveModels.
- Determine capable and enabled provider/model candidates for a given task (candidates) and classify requests into categories with classify.
- Dispatch generation requests to provider-specific implementations (geminiGen, openaiGen, anthropicGen) and provide a generic generate/post entry point for sending requests and recording outcomes.
- Estimate request costs (estCostUsd), check provider availability (isOpen), and record request successes or failures (recordSuccess, recordFailure).


---

## Constants and Types

| Name | Type | Value |
| --- | --- | --- |
| `ProviderId` | type alias | `"google" \| "openai" \| "anthropic"` |
| `Capability` | type alias | `"text" \| "image" \| "structured" \| "streaming"` |
| `TaskType` | type alias | `\| "chat" \| "analysis" \| "financial_insight" \| "report" \| "receipt_scan" \| "receipt_retry"` |
| `PROVIDER_ENV` | `Record<ProviderId, string>` | `{…}` |
| `DEFAULT_MODELS` | `ModelDef[]` | `[…]` |
| `SYSTEM` | — | `[…]` |



---

## Functions and Classes


### ModelDef

![Type: Abstract](https://img.shields.io/badge/Type-Abstract-purple) ![Attributes: 7](https://img.shields.io/badge/Attributes-7-blue)

#### Description

Represents a single AI model definition used by the gateway, providing identifying information, declared capabilities, throughput characteristics, priority, and activation state.

Serves as the canonical data structure for model metadata within the gateway module, enabling other components to evaluate, compare, and select models based on provider, capabilities, throughput, priority, and active status.

Responsibilities:
- Hold the provider identity (ProviderId) and the model's unique identifier (id).
- Declare the model's supported capabilities as an array of Capability values.
- Expose throughput or rate information via inputPerM and outputPerM to indicate allowed or expected tokens/units per minute for input and output.
- Indicate selection preference via the priority numeric value and whether the model is currently available via the active boolean.

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `provider` (class) | `ProviderId` | 🔓 public | Class attribute provider |
| `id` (class) | `string` | 🔓 public | Class attribute id |
| `caps` (class) | `Capability[]` | 🔓 public | Class attribute caps |
| `inputPerM` (class) | `number` | 🔓 public | Class attribute inputPerM |
| `outputPerM` (class) | `number` | 🔓 public | Class attribute outputPerM |
| `priority` (class) | `number` | 🔓 public | Class attribute priority |
| `active` (class) | `boolean` | 🔓 public | Class attribute active |

---



### requiredCaps

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def requiredCaps(task: TaskType) -> Capability[]:
```

#### Description

Determine and return the list of capabilities required to perform a given task.

The function maps a TaskType input to an array of Capability values representing the permissions or features needed for that task.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `task` | `TaskType` | ✅ | — |

#### Returns

**Type:** `Capability[]`

—

#### Complexity

Not analyzed

---



### costSensitive

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def costSensitive(task: TaskType) -> boolean:
```

#### Description

Determines whether the provided task should be treated as cost-sensitive.

Given a TaskType value, it evaluates and returns true when the task requires cost-sensitive handling and false otherwise.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `task` | `TaskType` | ✅ | — |

#### Returns

**Type:** `boolean`

—

#### Complexity

Not analyzed

---



### GatewayConfig

![Type: Abstract](https://img.shields.io/badge/Type-Abstract-purple) ![Attributes: 6](https://img.shields.io/badge/Attributes-6-blue)

#### Description

GatewayConfig defines the configuration shape for selecting and controlling AI providers and models used by the gateway.

Within the module, GatewayConfig serves as the canonical configuration object that other gateway components read to decide which providers and models to use, how to rank them, and how to handle pricing and fallback logic. It acts as the single source of truth for runtime selection and failover behavior.

Responsibilities:
- Declare which external providers are enabled via providerEnabled mappings.
- Specify provider selection order through providerPriority numeric rankings.
- Track which individual models are enabled using modelEnabled mappings.
- Provide per-model input pricing via modelPrice entries.
- Control model selection preference with modelPriority and limit resilience behavior with maxFallbackAttempts.

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `providerEnabled` (class) | `Record<string, boolean>` | 🔓 public | Class attribute providerEnabled |
| `providerPriority` (class) | `Record<string, number>` | 🔓 public | Class attribute providerPriority |
| `modelEnabled` (class) | `Record<string, boolean>` | 🔓 public | Class attribute modelEnabled |
| `modelPrice` (class) | `Record<string, { input: number` | 🔓 public | Class attribute modelPrice |
| `modelPriority` (class) | `Record<string, number>` | 🔓 public | Class attribute modelPriority |
| `maxFallbackAttempts` (class) | `number` | 🔓 public | Class attribute maxFallbackAttempts |

---



### loadConfig

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def loadConfig(db: SupabaseClient) -> Promise<GatewayConfig>:
```

#### Description

Reads the owner configuration from the database and returns it as a GatewayConfig, using default values whenever expected tables or rows are missing.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `db` | `SupabaseClient` | ✅ | — |

#### Returns

**Type:** `Promise<GatewayConfig>`

—

#### Complexity

Not analyzed

---



### effectiveModels

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def effectiveModels(cfg: GatewayConfig) -> ModelDef[]:
```

#### Description

Compute and return the list of effective models by taking the base model definitions and applying any configuration overlays or overrides specified in the provided gateway configuration.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `cfg` | `GatewayConfig` | ✅ | — |

#### Returns

**Type:** `ModelDef[]`

—

#### Complexity

Not analyzed

---



### candidates

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def candidates(task: TaskType, cfg: GatewayConfig) -> ModelDef[]:
```

#### Description

Returns an ordered list of model candidates for a given task.

The list is filtered so that models are capable of the requested task, provided by enabled providers, and have the required API key present in the gateway configuration.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `task` | `TaskType` | ✅ | — |
| `cfg` | `GatewayConfig` | ✅ | — |

#### Returns

**Type:** `ModelDef[]`

—

#### Complexity

Not analyzed

---



### Classified

![Type: Abstract](https://img.shields.io/badge/Type-Abstract-purple) ![Attributes: 1](https://img.shields.io/badge/Attributes-1-blue)

#### Description

The Classified interface defines a simple typed structure for representing a classification result that carries a code string.

Within the ai/gateway.ts file, Classified acts as a lightweight DTO (data-transfer object) used to pass classification codes between components. It helps ensure the rest of the module treats classification values in a consistent, typed way.

Responsibilities:
- Hold a classification identifier in the form of a string under the property 'code'.
- Provide a type-safe contract so TypeScript code can rely on the presence and type of the classification code.
- Serve as a predictable payload for functions or modules that consume or produce classification results.
- Enable consistent serialization and validation of classification data across the module.

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `code` (class) | `string` | 🔓 public | Class attribute code |

---



### classify

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def classify(status: number, message="") -> Classified:
```

#### Description

Determines and returns a classification based on a numeric status code and an optional message.

It interprets the provided status (and message if needed) to produce a Classified result used by the surrounding gateway logic.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `status` | `number` | ✅ | — |
| `message` = `""` | `Unknown` | ❌ | — |

#### Returns

**Type:** `Classified`

—

#### Complexity

Not analyzed

---



### Breaker

![Type: Abstract](https://img.shields.io/badge/Type-Abstract-purple) ![Attributes: 1](https://img.shields.io/badge/Attributes-1-blue)

#### Description

Represents the shape of a simple circuit-breaker-like object by exposing a failures count.

Within supabase/functions/_shared/ai/gateway.ts this interface defines the expected structure for breaker objects used by the gateway logic. It allows the module to reference and manipulate failure counts in a type-safe, predictable way.

Responsibilities:
- Hold the current number of recorded failures as a numeric value.
- Provide a consistent data shape that other parts of the code can rely on when inspecting failure state.
- Serve as the basis for decision-making about error handling or rate-limiting logic elsewhere in the module.

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `failures` (class) | `number` | 🔓 public | Class attribute failures |

---



### isOpen

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def isOpen(p: ProviderId) -> boolean:
```

#### Description

Determines whether the given provider identifier corresponds to an "open" provider.

It takes a ProviderId and returns a boolean indicating if that provider should be treated as open.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `p` | `ProviderId` | ✅ | — |

#### Returns

**Type:** `boolean`

—

#### Complexity

Not analyzed

---



### recordFailure

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def recordFailure(p: ProviderId) -> void:
```

#### Description

Record a failure occurrence for the specified AI provider so the system can track provider errors or adjust behavior based on recent failures.

It logs or updates internal state tied to the given provider identifier to reflect that a failure happened.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `p` | `ProviderId` | ✅ | — |

#### Returns

**Type:** `void`

—

#### Complexity

Not analyzed

---



### recordSuccess

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def recordSuccess(p: ProviderId) -> void:
```

#### Description

Records a successful event or outcome associated with the specified AI provider.

It updates internal state or metrics to reflect that the given ProviderId completed a successful operation.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `p` | `ProviderId` | ✅ | — |

#### Returns

**Type:** `void`

—

#### Complexity

Not analyzed

---



### GenResult

![Type: Abstract](https://img.shields.io/badge/Type-Abstract-purple) ![Attributes: 1](https://img.shields.io/badge/Attributes-1-blue)

#### Description

Represents the result of a text generation operation as a simple typed object.

Acts as the standard return/transfer shape for text generation results inside the AI gateway file, ensuring callers and implementers agree on the structure of generated text data.

Responsibilities:
- Contain the generated textual output via the 'text' string property.
- Serve as a typed contract for functions that produce or consume generated text.
- Enable consistent transmission and handling of generated text within the module.
- Provide a minimal, serializable shape for responses or intermediate results.

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `text` (class) | `string` | 🔓 public | Class attribute text |

---



### ProviderError

![Type: Concrete](https://img.shields.io/badge/Type-Concrete-green) ![Methods: 1](https://img.shields.io/badge/Methods-1-blue)

#### Description

ProviderError is a specialized Error subclass used to represent errors that originate from or are related to an external provider within the module.

Within the gateway.ts file, ProviderError serves as the module's explicit representation of provider-side problems, enabling the rest of the code to detect, propagate, and handle those errors in a consistent way. It acts as the canonical error type for interactions that involve external providers.

Responsibilities:
- Provide a dedicated error type for provider-related failures by extending the built-in Error class.
- Initialize and carry an error message and standard Error behavior via its constructor.
- Be thrown by code that encounters provider issues so callers can catch and handle provider-specific errors distinctly.
- Preserve stack and error semantics consistent with standard Error instances for debugging and logging.

#### Inheritance

**Inherits from:** `Error`

#### Methods

##### Public Methods

| Method | Type | Description |
| --- | --- | --- |
| `constructor` | instance | Method constructor.<br>**Signature:** `constructor(status: number, detail: string)` |

---



### constructor

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def constructor(status: number, detail: string):
```

#### Description

Initializes a new ProviderError instance using an HTTP status code and a detail message, setting up the error's internal properties and message accordingly.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `status` | `number` | ✅ | — |
| `detail` | `string` | ✅ | — |

#### Complexity

Not analyzed

---



### generate

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def generate(provider: ProviderId, model: string, system: string, prompt: string, /** Aborts the call (and reading its answer): the request's deadline. */
  signal?:AbortSignal) -> Promise<GenResult>:
```

#### Description

Asynchronously invokes an AI generation endpoint using the specified provider and model, supplying a system prompt and user prompt, and returns the generation result.

It supports aborting the request via an optional AbortSignal to stop the call and stop reading the response.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `provider` | `ProviderId` | ✅ | — |
| `model` | `string` | ✅ | — |
| `system` | `string` | ✅ | — |
| `prompt` | `string` | ✅ | — |
| `/** Aborts the call (and reading its answer)` | `the request's deadline. */
  signal?:AbortSignal` | ✅ | — |

#### Returns

**Type:** `Promise<GenResult>`

—

#### Complexity

Not analyzed

---



### post

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def post(url: string, headers: HeadersInit, body: unknown, signal: AbortSignal = undefined) -> Promise<Response>:
```

#### Description

Sends an HTTP POST request to the provided URL using the given headers and request body, optionally allowing cancellation via an AbortSignal.

The function is asynchronous and resolves with the fetch Response object when the request completes.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `url` | `string` | ✅ | — |
| `headers` | `HeadersInit` | ✅ | — |
| `body` | `unknown` | ✅ | — |
| `signal` = `undefined` | `AbortSignal` | ❌ | — |

#### Returns

**Type:** `Promise<Response>`

—

#### Complexity

Not analyzed

---



### geminiGen

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def geminiGen(model: string, sys: string, prompt: string, signal: AbortSignal = undefined) -> Promise<GenResult>:
```

#### Description

Asynchronously generate a response from a Gemini-style model using the provided system message and user prompt.

It sends the system context and prompt to the specified model and returns the generation result, optionally supporting request abortion via an AbortSignal.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `model` | `string` | ✅ | — |
| `sys` | `string` | ✅ | — |
| `prompt` | `string` | ✅ | — |
| `signal` = `undefined` | `AbortSignal` | ❌ | — |

#### Returns

**Type:** `Promise<GenResult>`

—

#### Complexity

Not analyzed

---



### openaiGen

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def openaiGen(model: string, sys: string, prompt: string, signal: AbortSignal = undefined) -> Promise<GenResult>:
```

#### Description

Asynchronously performs a text generation request to an OpenAI-style model using the provided model identifier, system message, and prompt, and returns the generation result.

It supports an optional AbortSignal to cancel the request.


The model, sys, and prompt parameters are strings identifying the model to use, the system-level message, and the user prompt respectively; the optional signal is an AbortSignal that can be used to abort the in-flight request.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `model` | `string` | ✅ | — |
| `sys` | `string` | ✅ | — |
| `prompt` | `string` | ✅ | — |
| `signal` = `undefined` | `AbortSignal` | ❌ | — |

#### Returns

**Type:** `Promise<GenResult>`

—

#### Complexity

Not analyzed

---



### anthropicGen

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def anthropicGen(model: string, sys: string, prompt: string, signal: AbortSignal = undefined) -> Promise<GenResult>:
```

#### Description

Asynchronously sends a prompt (with an optional system message) to an Anthropic model and returns the generated result.

It accepts the model identifier, a system-level instruction string, the user prompt, and an optional AbortSignal to cancel the request.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `model` | `string` | ✅ | — |
| `sys` | `string` | ✅ | — |
| `prompt` | `string` | ✅ | — |
| `signal` = `undefined` | `AbortSignal` | ❌ | — |

#### Returns

**Type:** `Promise<GenResult>`

—

#### Complexity

Not analyzed

---



### providerMsg

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def providerMsg(raw: string) -> string:
```

#### Description

Takes a raw provider message as input and produces a processed string representation suitable for downstream use.

It likely normalizes, formats, or sanitizes the incoming raw text into a consistent string output.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `raw` | `string` | ✅ | — |

#### Returns

**Type:** `string`

—

#### Complexity

Not analyzed

---



### estCostUsd

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def estCostUsd(m: ModelDef, inTok: number, outTok: number) -> number:
```

#### Description

Estimates the monetary cost in US dollars for using a given AI model based on the number of input and output tokens.

It calculates the cost by applying the pricing parameters contained in the provided ModelDef to the supplied inTok and outTok counts.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `m` | `ModelDef` | ✅ | — |
| `inTok` | `number` | ✅ | — |
| `outTok` | `number` | ✅ | — |

#### Returns

**Type:** `number`

—

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
