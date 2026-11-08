---
name: setup-repo
description: Use when the user starts a new repo or wants an existing one aligned with their devenv, just and lint tooling.
disable-model-invocation: true
---

# Setup repo

Templates live next to this file in `templates/`: `common/` for every repo, plus one stack directory (`ts/` or `rust/`). Copy them; do not retype them.

Every repo ends with the same contract:
- `.envrc` runs `use devenv`, so agent shells get the tools without wrapping commands.
- `just check` is the full gate (format check, lint, typecheck, test, build). The devenv pre-commit hook runs it.
- `just fix`, `just dev`, `just build`, `just test-one <name>`; bare `just` lists them.
- `tools/git-file-size-guard` runs as a pre-commit hook and blocks files over 5000 tokens.

## New TypeScript repo
1. Create the project with the framework the user names, using its own scaffolder with bun as the package manager (e.g. `bunx @tanstack/cli create <name> --package-manager bun --no-toolchain`). No framework named: `bun init -y`.
2. `cp -r <skill>/templates/common/. <skill>/templates/ts/. .`
3. `bun add -d oxfmt oxlint oxlint-tsgolint @types/bun`, and make sure `package.json` has a `dev` script.
4. Add the scaffold's generated paths (route trees, framework caches) to `ignorePatterns` in `.oxfmtrc.json` and `.oxlintrc.json`.
5. Invoke the `install-anti-slop` skill to vendor the anti-slop Oxlint plugin.
6. React UI: add `react` and `jsx-a11y` to the Oxlint plugins. Tailwind: set up `@shadcn/lint` for Oxlint by following https://github.com/shadcn-ui/lint/blob/main/SETUP.md.
7. Append `.devenv/` and `.direnv/` to `.gitignore`, then `direnv allow`.
8. `just fix`, then `just check` must pass.

## New Rust repo
1. `cp -r <skill>/templates/common/. <skill>/templates/rust/. .`, then set `name` in `Cargo.toml`.
2. In a workspace, move the `[lints.*]` tables to `[workspace.lints.*]` in the root manifest and add `lints.workspace = true` to each member.
3. Append `.devenv/`, `.direnv/` and `target/` to `.gitignore`, then `direnv allow`.
4. `just check` must pass.

## Align an existing repo
Compare instead of copying blindly:
- Keep the repo's working recipes; rename or add recipes so the contract above holds, and make `check` run everything CI runs.
- Merge `devenv.nix` hooks into an existing `devenv.nix`; keep its packages and services.
- Merge lint and formatter settings key by key. Report every rule the template adds that the code currently violates, and ask before mass-fixing.
- Leave existing husky or lefthook setups in place; add the size guard there instead of adding devenv hooks.
- Existing files over the cap: list them, add `<path> -file-size-guard` to `.gitattributes` for each, and tell the user they need splitting.
