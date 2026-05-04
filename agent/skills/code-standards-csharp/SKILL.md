---
name: code-standards-csharp
description: C# 14 coding standards
---

- Use `extension` blocks for multiple related extension members; keep `this` methods for single helpers
- Prefer `field` backed properties for simple validation; explicit backing fields for complex logic
- Use null-conditional assignment `?.` and `?[]` over manual null checks
- Use unbound generic `nameof` for type references in logging/exceptions
- Use `Span<T>`/`ReadOnlySpan<T>` params and overloads for hot paths; `IEnumerable<T>` for streams
- Apply lambda modifiers (`ref`, `in`, `scoped`, `ref readonly`) only when the contract demands it
- Reserve `partial` constructors/events for source generators; avoid in hand-written domain code
- Implement compound assignment operators (`+=`, `-=`) only when semantics are intuitive
- Prefer `required` init-only properties over complex constructors for mandatory data
- Use `readonly` fields and records for immutable data; seal classes by default
- Avoid `async void`; always return `Task` or `ValueTask`
- Use `is` pattern matching over `as` + null check
- Prefer `ArgumentNullException.ThrowIfNull` over manual validation
- Keep LINQ method syntax; query syntax only for simple joins
- Enable nullable reference types and treat warnings as errors
