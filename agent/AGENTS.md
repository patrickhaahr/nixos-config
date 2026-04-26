# Global Agent Guidelines

This file contains guidelines for AI coding agents working across all projects.

## General Guidelines

### Philosophy
This codebase will outlive you. Every shortcut you take becomes
someone else's burden. Every hack compounds into technical debt
that slows the whole team down.

You are not just writing code. You are shaping the future of this
project. The patterns you establish will be copied. The corners
you cut will be cut again.

Fight entropy. Leave the codebase better than you found it.

### Bug fixing
When I report a bug, don't start by trying to fix it.
Instead, start by writing a test that reproduces the bug.
Then, have subagents try to fix the bug and prove it with a passing test.

### Code Style
- Follow existing project conventions (check for .editorconfig, .prettierrc, eslintrc files)
- Use consistent indentation (detect from existing files)
- Use descriptive variable/function names (avoid single letters except loop counters)
- Design for testability using "functional core, imperative shell": keep pure business logic separate from code that does IO

### Imports
- Group imports: external packages first, then internal modules
- Remove unused imports
- Use absolute imports when configured in the project

### Error Handling
- Always handle errors explicitly (no silent failures)
- Use try-catch for async operations
- Log errors with context
- Return meaningful error messages

### Testing
**Quality over Quantity**: You should prefer 40% coverage with extremely well thought through tests over 100% coverage.
- Write tests for new features
- Run tests before completing tasks
- Focus on meaningful coverage rather than arbitrary coverage targets
- Design tests following "functional core, imperative shell" patterns. 
- **Functional core**: Test pure logic independent of IO
- Common test commands: `bun test`, `cargo test`

### File Operations
- Always read files before editing
- Preserve existing formatting and style
- Never create files unnecessarily - prefer editing existing ones
- Don't create documentation unless explicitly requested

## Project-Specific
Check for project-specific agent instructions in:
- `AGENTS.md` in project root

## Navigation Strategy
For ANY task involving file discovery or codebase exploration, use the `explore` subagent:
- Finding files by pattern (route*, *api*, handlers, etc.)
- Searching for code related to features, routes, endpoints
- Exploring directory structure or module organization
- Any task that would require multiple glob/grep calls

Do NOT use glob/grep tools directly for these tasks. Delegate to explore.

## Knowledge Strategy
- ALWAYS Check if any relevant skills available should be used
- If unsure use exa.ai `websearch` and `codesearch` tools
- If stuck use `context7` mcp tool
