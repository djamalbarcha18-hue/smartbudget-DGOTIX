<!-- METADATA: {"source_path": "supabase/tests/fake_supabase.ts", "source_sha": "c24b756b48e706ac43dd58ef7d34fbc499b43c1d", "extraction_quality": "structural", "model": "gpt-5-mini", "generated_at": "2026-11-19T21:41:34Z", "doc_type": "file"} -->
<details>
<summary>Documentation Metadata (click to expand)</summary>

```json
{
  "doc_type": "file_overview",
  "file_path": "supabase/tests/fake_supabase.ts",
  "source_hash": "455e30460f86041a39744a14aa7833b50701be34c2309fd93eef760b87d88203",
  "last_updated": "2026-11-19T21:41:34.445995+00:00",
  "git_sha": "c24b756b48e706ac43dd58ef7d34fbc499b43c1d",
  "tokens_used": 12312,
  "complexity_score": 3,
  "estimated_review_time_minutes": 9,
  "external_dependencies": []
}
```

</details>

[Documentation Home](../../README.md) > [supabase](../README.md) > [tests](./README.md) > **fake_supabase**

---

# fake_supabase.ts

> **File:** `supabase/tests/fake_supabase.ts`

![Complexity: Low](https://img.shields.io/badge/Complexity-Low-green) ![Review Time: 9min](https://img.shields.io/badge/Review_Time-9min-blue)

## 📑 Table of Contents


- [Overview](#overview)
- [Dependencies](#dependencies)
- [Architecture Notes](#architecture-notes)
- [Maintenance Notes](#maintenance-notes)
- [Functions and Classes](#functions-and-classes)

---

## Overview

This file provides a lightweight fake Supabase test harness and helpers for use in tests. It exports a Q class plus a set of module-level utility functions that simulate common Supabase behaviors: creating a test client, resolving or failing promises, reserving resources, constructing SQL literals for call arguments, delivering subscription events, and interacting with a Postgres-like test environment. A SupabaseClient type alias is present (typed as any) and createClient produces a client instance suitable for test scenarios.

Several functions are asynchronous and intended to model remote interactions: applySubscriptionEvent and onPostgres run async workflows against the fake environment, and getUser parses an authorization header such as "Bearer user-<id>" to return the corresponding user or Postgres account representation. The file centralizes utilities that make it straightforward to simulate authentication, database callbacks, and real-time subscription events in unit and integration tests that depend on Supabase-like semantics.

## Dependencies

No dependencies identified.

## 📁 Directory

This file is part of the **tests** directory. View the [directory index](./README.md) to see all files in this module.

## Architecture Notes

- Contains multiple async functions to simulate remote or I/O-bound Supabase interactions.
- Exports a test client factory (createClient) alongside helper utilities for simulating events and auth.
- Includes a SQL literal helper (lit) for passing raw SQL fragments into simulated calls.

## Maintenance Notes

- Provide a Q class to encapsulate query or test-specific behavior used across the fake Supabase harness.
- Offer utility functions (t, fail, reserve) to control test flow and simulate success/failure scenarios.
- Expose lit to construct SQL literal arguments for function calls in tests.
- Support async simulation of server-side behaviors via applySubscriptionEvent and onPostgres.
- Create test clients and resolve test users from authorization strings with createClient and getUser.


---

## Constants and Types

| Name | Type | Value |
| --- | --- | --- |
| `SupabaseClient` | type alias | `any` |



---

## Functions and Classes


### t

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def t(n: string) -> Row[]:
```

#### Description

Takes a string argument and returns an array of Row objects based on that input.

The function likely looks up, generates, or filters rows using the provided string identifier or key.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `n` | `string` | ✅ | — |

#### Returns

**Type:** `Row[]`

—

#### Complexity

Not analyzed

---



### fail

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def fail(n: string):
```

#### Description

Takes a single string argument and triggers or records a failure identified by that string.

The function is intended for use in test or fake implementations to indicate an error condition associated with the provided name.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `n` | `string` | ✅ | — |

#### Complexity

Not analyzed

---



### Q

![Type: Concrete](https://img.shields.io/badge/Type-Concrete-green) ![Methods: 16](https://img.shields.io/badge/Methods-16-blue) ![Attributes: 2](https://img.shields.io/badge/Attributes-2-blue)

#### Description

Q is a small query-builder and executor used in tests to represent database operations against a fake Supabase interface.

Within supabase/tests/fake_supabase.ts, Q functions as the test-side representation of a Supabase query object: it lets test code build, filter, run, and inspect fake database operations in a way that mirrors the real client.

Responsibilities:
- Hold and manage a list of filter predicates that will be applied to row data (filters).
- Provide methods to compose common query operators and conditions (eq, is, gte, lt, in, match).
- Expose CRUD-style operation starters for composing requests (select, insert, upsert, update, delete).
- Execute composed queries and return results in different forms, including run, maybeSingle, single, and support for promise chaining via then.

#### Attributes

| Attribute | Type | Visibility | Description |
| --- | --- | --- | --- |
| `filters` (class) | `Array<(r: Row)` | 🔓 public | Class attribute filters<br>**Default:** `> boolean> = []` |
| `op` (class) | `Unknown` | 🔓 public | Class attribute op<br>**Default:** `"      "` |

#### Methods

##### Public Methods

| Method | Type | Description |
| --- | --- | --- |
| `constructor` | instance | Method constructor.<br>**Signature:** `constructor(name: string)` |
| `select` | instance | Method select.<br>**Signature:** `select(cols = "*", o: any = undefined)` |
| `insert` | instance | Method insert.<br>**Signature:** `insert(p: any)` |
| `upsert` | instance | Method upsert.<br>**Signature:** `upsert(p: any)` |
| `update` | instance | Method update.<br>**Signature:** `update(p: any)` |
| `delete` | instance | Method delete.<br>**Signature:** `delete()` |
| `eq` | instance | Method eq.<br>**Signature:** `eq(c: string, v: any)` |
| `is` | instance | Method is.<br>**Signature:** `is(c: string, v: any)` |
| `gte` | instance | Method gte.<br>**Signature:** `gte(c: string, v: any)` |
| `lt` | instance | Method lt.<br>**Signature:** `lt(c: string, v: any)` |
| `in` | instance | Method in.<br>**Signature:** `in(c: string, v: any[])` |
| `match` | instance | Method match.<br>**Signature:** `match(r: Row)` |
| `run` | instance | Method run.<br>**Signature:** `async run(): Promise<any>` |
| `maybeSingle` | instance | Method maybeSingle.<br>**Signature:** `async maybeSingle()` |
| `single` | instance | Method single.<br>**Signature:** `async single()` |
| `then` | instance | Method then.<br>**Signature:** `then(res: any, rej: any)` |

---



### constructor

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def constructor(name: string):
```

#### Description

Creates a new instance of the Q class, initializing the object with the provided name.

It sets up any internal state that depends on the given name for the lifetime of the instance.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | `string` | ✅ | — |

#### Complexity

Not analyzed

---



### select

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def select(cols="*", o: any = undefined):
```

#### Description

Configure the selection of columns for a query on the Q object.

It sets which columns (or expressions) should be returned when the query is executed, with a default of '*' to select all columns.


cols is a string (default "*") specifying which columns or expressions to select; o is an optional parameter for additional options or modifiers for the select operation.

Returns a value representing the modified query or the result of applying the selection (specific return type is not specified in the signature).

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `cols` = `"*"` | `Unknown` | ❌ | — |
| `o` = `undefined` | `any` | ❌ | — |

#### Complexity

Not analyzed

---



### insert

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def insert(p: any):
```

#### Description

Inserts the provided value or record into whatever storage or test double Q represents.

This method forwards the given data to the instance's insert logic so the item becomes part of the fake Supabase test state.


p is the value or record to insert; its type is any, so it may be a single record or a structure expected by the fake insert implementation.

Returns the result of the insert operation as implemented by this fake; the exact return shape is not specified by the signature.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `p` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### upsert

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def upsert(p: any):
```

#### Description

Performs an upsert operation using the provided payload, inserting the data if it does not exist or updating the existing entry if a matching record is found.

It is used in tests to simulate Supabase-style insert-or-update behavior against the fake dataset.


p is the payload to upsert; it may be a single record or a collection of records (typed as any) that will be inserted or used to update matching entries in the fake storage.

Returns the upsert result, typically the inserted or updated record(s) or a result object indicating the outcome of the operation.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `p` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### update

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def update(p: any):
```

#### Description

Performs an update operation using the provided argument.

It applies the given data or patch to whatever target the Q.update method is meant to modify in this fake Supabase test helper.


p is the payload or patch to apply for the update; its structure and contents are unrestricted (typed as any) and represent the new values or changes to be applied.

Returns the result of the update operation; the specific return type or value is not specified in the signature.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `p` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### delete

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def delete():
```

#### Description

Performs a delete operation associated with this query object, removing the records targeted by the query.

#### Complexity

Not analyzed

---



### eq

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def eq(c: string, v: any):
```

#### Description

Defines an equality condition using a column name and a value, i.e., represents or records that the column c should equal the value v.

It is a method of the Q class for constructing or capturing such equality expressions.


Returns a value representing the constructed equality condition (the exact return type is not specified in the provided signature).

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `c` | `string` | ✅ | — |
| `v` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### is

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def is(c: string, v: any):
```

#### Description

Defines or applies an equality condition using the string identifier c and the value v.

It is intended to express that the item identified by c should be equal to the provided value v, typically for assertions or filtering within Q.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `c` | `string` | ✅ | — |
| `v` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### gte

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def gte(c: string, v: any):
```

#### Description

Apply a greater-than-or-equal comparison using column c and value v; likely used to add a >= condition to a query or filter.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `c` | `string` | ✅ | — |
| `v` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### lt

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def lt(c: string, v: any):
```

#### Description

Creates a less-than condition for a query using the specified column and comparison value.

It records that column c should be less than value v for whatever query or filter Q represents.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `c` | `string` | ✅ | — |
| `v` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### in

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def in(c: string, v: any[]):
```

#### Description

Constructs or applies an 'IN' condition using the provided column name and list of values.

It is intended to restrict results so that the column c matches one of the elements in the array v.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `c` | `string` | ✅ | — |
| `v` | `any[]` | ✅ | — |

#### Complexity

Not analyzed

---



### match

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def match(r: Row):
```

#### Description

Evaluate whether a given row satisfies the query criteria represented by this Q instance.

It determines if the provided Row matches the conditions encapsulated by Q.


Returns a boolean indicating true when the row meets the Q instance's matching conditions and false otherwise.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `r` | `Row` | ✅ | — |

#### Complexity

Not analyzed

---



### run

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def run() -> Promise<any>:
```

#### Description

Asynchronously performs the operation represented by this Q instance and yields its result.

The method runs whatever work this query object encapsulates and completes when the operation finishes.

#### Returns

**Type:** `Promise<any>`

—

#### Complexity

Not analyzed

---



### maybeSingle

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def maybeSingle():
```

#### Description

Asynchronous method that attempts to obtain a single result from the query/context represented by class Q; it is intended to return at most one item and handle cases where no item is present.

Resolves to a single item when available or a null/undefined-like value when no item exists.

#### Complexity

Not analyzed

---



### single

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def single():
```

#### Description

Asynchronously executes the query represented by this Q instance and resolves to a single result.

It is intended to retrieve one record or value from the underlying operation represented by the object.


Returns a Promise that resolves to the single result produced by the query (e.g., a single record or value).

#### Complexity

Not analyzed

---



### then

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def then(res: any, rej: any):
```

#### Description

Provides a promise-like continuation point by accepting a fulfillment handler and a rejection handler to be invoked when the object's asynchronous operation completes.

It enables chaining of subsequent behavior based on success or failure.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `res` | `any` | ✅ | — |
| `rej` | `any` | ✅ | — |

#### Complexity

Not analyzed

---



### reserve

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def reserve(a: any) -> string:
```

#### Description

Takes a single argument and produces a string result.

It likely converts, formats, or encodes the provided input into a string suitable for use in tests or as a placeholder value.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `a` | `any` | ✅ | — |

#### Returns

**Type:** `string`

—

#### Complexity

Not analyzed

---



### lit

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def lit(v: any) -> string:
```

#### Description

Returns a SQL literal representation of the provided value to be used as a call argument.

This function converts the input into a string suitable for embedding directly in SQL calls.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `v` | `any` | ✅ | — |

#### Returns

**Type:** `string`

—

#### Complexity

Not analyzed

---



### applySubscriptionEvent

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def applySubscriptionEvent(a: any) -> Promise<any>:
```

#### Description

Asynchronously applies a subscription event within the fake Supabase test environment.

It processes the provided event payload and updates the test subscription state or triggers any associated handlers accordingly.


a is the subscription event payload (of arbitrary shape) that should be applied to the fake Supabase subscription system; the function will interpret and act on this payload.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `a` | `any` | ✅ | — |

#### Returns

**Type:** `Promise<any>`

—

#### Complexity

Not analyzed

---



### onPostgres

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def onPostgres(fn: string, a: any) -> Promise<any>:
```

#### Description

Asynchronously invokes or handles a Postgres-related operation identified by the string parameter fn, passing the value a as its argument or payload.

It is intended for use in the test helper file to simulate or route requests to a fake Supabase/Postgres backend.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `fn` | `string` | ✅ | — |
| `a` | `any` | ✅ | — |

#### Returns

**Type:** `Promise<any>`

—

#### Complexity

Not analyzed

---



### getUser

![Type: Async](https://img.shields.io/badge/Type-Async-blue)

#### Signature

```typescript
async def getUser(tok: string) -> Promise<any>:
```

#### Description

Parses an authorization token and resolves it to a user object.

If the token is of the form "Bearer user-<id>", it returns that user; when running against Postgres it returns the account as stored in auth.users, otherwise it fabricates an old, confirmed account for ids starting with "new".


tok is the authorization token string; a special form is "Bearer user-<id>", which identifies a specific user by id.

Resolves to a user representation (from auth.users on Postgres or a synthetic confirmed account for "new" ids).

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `tok` | `string` | ✅ | — |

#### Returns

**Type:** `Promise<any>`

Resolves to a user representation (from auth.users on Postgres or a synthetic confirmed account for "new" ids).

#### Complexity

Not analyzed

---



### createClient

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def createClient(*_args: unknown[]) -> any:
```

#### Description

Creates a fake Supabase client for use in tests.

The function accepts any arguments and returns an object that mimics a Supabase client API and includes nested helper functions named row and life.


Returns a test double (an object typed as any) that represents a fake Supabase client, exposing the nested row and life helper functions.

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `_args` | `unknown[]` | ❌ | — |

#### Returns

**Type:** `any`

Returns a test double (an object typed as any) that represents a fake Supabase client, exposing the nested row and life helper functions.

#### Complexity

Not analyzed

---



### row

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def row(r):
```

#### Description

Creates or returns a row representation from the provided input for use in the fake Supabase test utilities.

It wraps or normalizes the given value into the shape expected for a test row.


r is the input value (likely an object or primitive) that will be converted into or wrapped as the test row; its exact expected shape is not specified by the signature.

Returns the constructed or normalized row value/object suitable for use in tests (the exact type is not specified by the signature).

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `r` | `Unknown` | ✅ | — |

#### Complexity

Not analyzed

---



### life

![Type: Sync](https://img.shields.io/badge/Type-Sync-green)

#### Signature

```typescript
def life(r):
```

#### Description

A helper function named life that performs an operation using the single input argument r.

The function likely encapsulates some behavior or transformation related to the provided value within the fake_supabase test helper file.


r is the sole input to the function; its meaning is not specified here but it is the primary value the function operates on (for example a request, record, or response object).

#### Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `r` | `Unknown` | ✅ | — |

#### Complexity

Not analyzed

---



---

## Navigation

**↑ Parent Directory:** [Go up](./README.md)

---

*This documentation was automatically generated by AI ([Woden DocBot](https://github.com/marketplace/ai-document-creator)) and may contain errors. It is the responsibility of the user to validate the accuracy and completeness of this documentation.*
