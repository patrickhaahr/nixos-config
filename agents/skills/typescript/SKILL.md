---
name: typescript
description: Invoke when working in TypeScript or .ts or .tsx code.
---

The repo's own conventions win. In an Effect codebase, follow the `effect` skill for failures, services and schemas. Mechanical rules (`any`, `!`, casts, barrels, module mocks, import shape) are enforced by oxlint through anti-slop: fix the lint, keep it on.

## Failures

- Expected failures (domain, parse, authorization, I/O, persistence) appear in the return type: `Promise<Result<User, UserNotFound | UserStoreUnavailable>>`. A rejected promise counts as a throw.
- Result type: Effect if present, else `better-result`, else a local `{ _tag: "ok"; value } | { _tag: "err"; error }`.
- Throw only for defects (broken invariants, impossible branches, startup misconfiguration), through `casesHandled(x: never)`, `shouldNeverHappen` and `notYetImplemented` in `prelude.ts`.
- Errors are tagged classes: stable `_tag`, message, structured context fields, optional `cause`. Keep unions precise; a broad `AppError` belongs only at entrypoints.
- At framework boundaries, translate typed errors into what the framework, logging and tracing expect.

## Boundaries

- Parse into domain types at the edge: `unknown → DTO → domain input`. `z.infer` types stay at the boundary.
- `parseX` turns untrusted input into a `Result`, `makeX` builds a value from typed pieces, `isX` is a predicate. A function that returns a refined value is a parser.
- Schemas: the repo's library, Effect Schema with Effect, `StandardSchemaV1<unknown, T>` for generic helpers, otherwise Zod 4.
- Parse config once at startup into typed config. Wrap secrets in `Redacted<T>` and unwrap them only inside the adapter that sends them.
- Database rows and ORM models are DTOs: adapters return parsed domain types and typed errors.

## Types

- Brand meaningful primitives (`UserId`, `EmailAddress`, `Cents`, `Milliseconds`) and construct them only through parse or make.
- Derive types from their source (`Pick`, `Omit`, `ReturnType`, `Awaited`, `typeof`) and let them flow from schema to client.
- Push optionality outward: a function that needs a value takes it as required. Each operation gets an explicit input type rather than `Partial<T>`.
- Behaviour switches are named options or unions (`{ emailVerification: "skip" }`).
- Object arguments by default; positional only on proven hot paths.
- `satisfies` checks a literal against a type without widening it.
- A cast carries a `// SAFETY:` comment naming the invariant the type system cannot express. A type guard checks exactly what it claims.
- Inputs are `readonly` and `ReadonlyArray`; mutation stays local inside the imperative shell.

## Modules

- One domain module per concept (`email-address.ts`): the type plus its parse, make, combinators and predicates, imported as `import * as EmailAddress`.
- Application modules (`PasswordReset`, `Billing`) are classes with constructor injection when they hold dependencies. Each depends on the narrowest structural type it uses; adapters may be wider.
- Reuse or extend an existing adapter before creating a new one.
- Name files by concept. `prelude.ts` holds only tiny generic helpers (`casesHandled`, `Redacted`, Result helpers).
- Side effects run from entrypoints only. Inject `Clock` and `Random`; pure functions take `now` as an argument.
- Entrypoints (HTTP, CLI, workers) parse, call shared modules and render. Authorization lives in shared policy that takes a parsed principal.

## Workflows

- A retried step has an idempotency strategy: key, unique constraint, dedup record or state-transition guard.
- Transactions close before any network call. Processes that span several transactions with retries or compensation use a saga or durable workflow.

## Tests

- Test through real seams: constructor-injected fakes, Effect layers, SQLite, Miniflare or LocalStack where storage or platform behaviour matters. Assert returned values, persisted state and emitted messages.
- Use `fast-check` for parsers, branded types, roundtrips and state transitions, with `x.arbitrary.ts` next to the domain module.
