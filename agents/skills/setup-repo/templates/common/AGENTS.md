# AGENTS

## Verification
- Run `just check` before handing back; it applies formatter and lint autofixes first, and the pre-commit hook runs it too. Stage everything it rewrote before committing.
- `just test-one <name>` runs one test while iterating.
