---
name: code-standards-rust
description: Rust coding standards for production code
---

### Patterns
- Use `?` for early returns; avoid `match` on `Result`/`Option` for propagation
- Use `if let`/`let else` for single-pattern extraction; `match` for multiple arms
- Never `match` on booleans; use `if/else`
- Prefer iterator adapters (`filter_map`, `find_map`) over manual loops
- Early returns over nesting

### Ownership
- `&str` > `String`, `&[T]` > `Vec<T>`, `&Path` > `PathBuf` for parameters
- Question every `.clone()`; prefer borrowing
- Use `.as_ref()` to convert `&Option<T>` → `Option<&T>`
- Move with `into_iter()` over `iter().cloned()`
- Keep borrows short-lived; avoid `Rc<RefCell<T>>` unless shared mutability is required

### API Design
- Make illegal states unrepresentable (enums > bool flags)
- Newtypes for semantic distinctions (`struct UserId(u64)`)
- Builders for many optional parameters
- Private by default; `pub(crate)` before `pub`
- Derive `Debug` always; `Copy` only for small value types

### Error Handling
- No `.unwrap()`/`.expect()` in library/production code without `// SAFETY:` comment
- Use `Result` for recoverable failures, `Option` for absence
- Custom error types for libraries; `anyhow`/`thiserror` for applications
- Add context when crossing layer boundaries

### Unsafe
- Isolate to smallest scope possible
- Every `unsafe` block needs invariant documentation
- Safe wrappers around unsafe internals
- No unsafe for "performance" without profiling proof

### Anti-patterns
- Nested `if let` chains → early returns
- `Vec<T>` parameters where `&[T]` suffices
- Public mutable fields
- Deep mixing of I/O, logic, and parsing in one function
- `unsafe` without documented invariants
- Ignoring clippy warnings without justification
