---
name: code-standards-typescript
description: TypeScript/React coding standards. Invoke this skill always when working in TypeScript language.
---

- Use ES modules with proper import sorting and extensions
- Prefer `function` keyword over arrow functions for top-level
- Explicit return type annotations for exported functions
- React: explicit Props types, function components
- Never use `any`; prefer precise types, generics, `unknown`, or narrowing
- Avoid try/catch when possible (return errors as values)
- No nested ternaries - use switch or if/else chains
