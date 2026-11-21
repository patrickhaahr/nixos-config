---
name: setup-repo
description: Scaffold a new repo, or align an existing one, with the devenv, just and lint tooling.
disable-model-invocation: true
---

# Setup repo

Templates live next to this file in `templates/`: `common/` for every repo, plus one stack directory (`typescript/`, `rust/`, `python/` or `csharp/`). Copy them; do not retype them.

Copy `tools/ast-grep/no-comments.yml` whole, even its sections for languages the repo lacks: ast-grep skips a language with no section, so a deleted one lets that language's comments through unseen. Add a section for a missing language; never delete one.

Every repo ends with the same contract:
- `.envrc` runs `use devenv`, so agent shells get the tools without wrapping commands.
- `just check` is the full gate and applies safe fixes first (format, lint autofix, comment-baseline lowering), then lints, typechecks, tests and builds. The devenv pre-commit hook runs it and fails when it rewrites a file: stage everything and commit again. CI, when a repo has it, runs `just check && git diff --exit-code`.
- `just dev`, `just test-one <name>`, and `just build` where the stack ships a release build; bare `just` lists them.
- `tools/git-file-size-guard` runs as a pre-commit hook and blocks files over 5000 tokens.
- `tools/comment-guard` runs in `just check` and ratchets comments: each file may hold at most its count of comment lines in `tools/comment-baseline` (absent means zero), and `just check` only lowers it. It skips paths marked `linguist-vendored`, `linguist-generated` or `-comment-guard` in `.gitattributes`.

## New TypeScript repo
1. Create the project with the framework the user names, using its own scaffolder with bun as the package manager (e.g. `bunx @tanstack/cli create <name> --package-manager bun --no-toolchain`). No framework named: `bun init -y`.
2. `cp -r <skill>/templates/common/. <skill>/templates/typescript/. .`
3. `bun add -d oxfmt oxlint oxlint-tsgolint @types/bun`, and make sure `package.json` has a `dev` script.
4. Add the scaffold's generated paths (route trees, framework caches) to `ignorePatterns` in `.oxfmtrc.json` and `.oxlintrc.json`, and mark the committed ones `linguist-generated` in `.gitattributes`.
5. Vendor the anti-slop Oxlint plugin by following `~/.agents/skills/install-anti-slop/SKILL.md`; it is manual-only, so read the file instead of invoking it. Mark `tools/oxlint/anti-slop/**` `linguist-vendored` in `.gitattributes`.
6. React UI: add `react` and `jsx-a11y` to the Oxlint plugins. Tailwind: set up `@shadcn/lint` for Oxlint by following https://github.com/shadcn-ui/lint/blob/main/SETUP.md.
7. Append `.devenv/` and `.direnv/` to `.gitignore`, then `direnv allow`.
8. Delete the scaffold's comments with `ast-grep scan --update-all <its source paths>`, then `just check` must pass.

## New Rust repo
1. `cp -r <skill>/templates/common/. <skill>/templates/rust/. .`, then set `name` in `Cargo.toml`.
2. In a workspace, move the `[lints.*]` tables to `[workspace.lints.*]` in the root manifest and add `lints.workspace = true` to each member.
3. Append `.devenv/`, `.direnv/` and `target/` to `.gitignore`, then `direnv allow`.
4. `just check` must pass.

## New Python repo
1. `uv init --app --package --python 3.15 <name>`, `cd <name>`, then `uv add --dev pytest`. Ruff and basedpyright come from devenv; never `uv add` them.
2. `cp -r <skill>/templates/common/. <skill>/templates/python/. .`, then set `app` in the `justfile` to the `[project.scripts]` name.
3. Append `.devenv/`, `.direnv/` and `.ruff_cache/` to `.gitignore`, then `direnv allow`.
4. Delete the scaffold's comments with `ast-grep scan --update-all src`, then `just check` must pass.

## New C# repo
1. `cp -r <skill>/templates/common/. <skill>/templates/csharp/. .`, then `dotnet new sln -n <Name>`, `dotnet new console -o src/<Name>`, and set `app` in the `justfile` to `src/<Name>`.
2. `dotnet new install TUnit.Templates`, `dotnet new TUnit -o tests/<Name>.Tests`, `dotnet sln add src/<Name> tests/<Name>.Tests` and `dotnet add tests/<Name>.Tests reference src/<Name>`. Replace the template's sample tests, which break the analyzers, with one test of the app.
3. `dotnet new gitignore`, append `.devenv/` and `.direnv/`, then `direnv allow`.
4. Delete the scaffold's comments with `ast-grep scan --update-all src tests`, then `just check` must pass.

## Other stacks
Copy `common/` alone and write the `justfile` and `devenv.nix` by hand, wrapping the stack's own CLI so the contract above holds. Mark vendored engine or SDK directories `linguist-vendored`.

## Align an existing repo
Compare instead of copying blindly:
- Keep the repo's working recipes; rename or add recipes so the contract above holds, and make `check` run everything CI runs.
- Merge `devenv.nix` hooks into an existing `devenv.nix`; keep its packages and services.
- Merge lint and formatter settings key by key. Report every rule the template adds that the code currently violates, and ask before mass-fixing; once approved, land the repo-wide format and autofix as its own commit before the hook goes live.
- Leave existing husky or lefthook setups in place; add the size guard there instead of adding devenv hooks.
- Existing files over the cap: list them, add `<path> -file-size-guard` to `.gitattributes` for each, and tell the user they need splitting.
- Existing comments: add a `tools/ast-grep/no-comments.yml` section per missing language (`ast-grep run -l <lang> -p '// x' --debug-query=cst` names its comment kinds), mark vendored and generated paths, run `bash tools/comment-guard --init`, and add `tools/comment-baseline -file-size-guard` to `.gitattributes`. Report the total; `/delete-comment` works it down.
