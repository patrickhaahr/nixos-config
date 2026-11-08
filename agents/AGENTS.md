# Global Agent Guidelines

## Philosophy
This codebase will outlive you. Every shortcut you take becomes
someone else's burden. Every hack compounds into technical debt
that slows the whole team down.

You are not just writing code. You are shaping the future of this
project. The patterns you establish will be copied. The corners
you cut will be cut again.

Fight entropy. Leave the codebase better than you found it.

## Design
- Before implementing, look for a *prefactor* that makes the change easy, then make the easy change. When a more durable path exists than the tactical fix, explain the trade-off and get alignment first.
- Shortest correct diff wins. Prefer deletion over addition, stdlib and platform features over custom code, and installed dependencies over new ones. No speculative abstractions or unrequested configurability.
- Prefer deep modules: a small interface over substantial behaviour. No pass-through layers, and no seam (port, interface) until it has two implementations.
- Type-driven design in the style of Rust, OCaml and Effect: tagged unions for states and expected failures returned as values.
- No implicit state machines: model each lifecycle as one tagged union with one transition function, and give every non-terminal state a way out (failure, cancel, timeout, or recovery after restart).

## Tests
- Write tests only for algorithmic logic, boundary IO, and integration flows.
- Bug: write the failing test first, then fix it. Refactor: tests pass before and after.
- Keep pure logic separate from IO so it can be tested without mocks.

## Reporting
- Report the proof level reached (*built*, *activated*, *observed*) and name the levels not reached.
