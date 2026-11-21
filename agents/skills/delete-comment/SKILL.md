---
name: delete-comment
description: Classify a repo's code comments, move decisions into ADRs and hacks into issues, delete them, and lower the comment ratchet.
disable-model-invocation: true
---

# Delete comments

`tools/comment-guard` is a ratchet: `tools/comment-baseline` counts the comments each file still holds, and counts only fall. One run takes one **scope** (the paths the user names, else the top-level directory with the most comments in the baseline) and drives it to the floor without losing what the comments knew.

## 1. Guard
No `tools/comment-guard` yet: read `~/.agents/skills/setup-repo/SKILL.md` (manual-only, so read the file), copy `sgconfig.yml`, `tools/ast-grep/` and `tools/comment-guard` from its `templates/common/`, and follow its "Align an existing repo" section.

Done when `just check` runs the guard and `tools/comment-baseline` exists.

## 2. Inventory
`ast-grep scan --json=stream <scope>` prints one JSON line per comment (`file`, `range`, `text`). Group adjacent own-line comments into one **block**, and note the scope's comment and line totals.

Done when every block in scope is on your list.

## 3. Classify
Read each block with the code it sits on and give it one label:

- **Tautology**: restates the names, types or control flow, including banners, closing-brace labels and docs that paraphrase a signature.
- **Stale**: describes code or behaviour that is gone, or repeats a source of truth kept elsewhere (an ADR, `docs/`, a skill, a config).
- **Excuse**: covers for a shortcut. Scent: `IMPORTANT`, `do not remove`, `for now`, `hack`, `workaround`, a long justification, tuple fields named only in prose, magic numbers derived in prose, a lifecycle explained instead of modelled, a rule kept "in step with" another copy, or a suppression of a rule that guards correctness.
- **Decision record**: a constraint the code cannot show, such as a platform quirk, a security invariant, a protocol limit or why an alternative lost.

**Keeps** sit outside the labels and stay in the baseline:

- Doc comments the program reads: clap `--help`, schema descriptions, Rust doctests. Shrink them by moving the text into attributes (`#[arg(help = "...")]`, `#[schemars(description = "...")]`) or the doctest into a unit test, with the output unchanged.
- Licence notices the guard's pattern missed.
- Files a tool checksums, such as applied migrations.

Done when every block has a label, a few-word reason and a destination.

## 4. Move
- **Decision record**: into the repo's ADR directory (`docs/adr/` when none exists) in the **domain-modeling** skill's format, grouped by theme, extending an existing ADR on that theme, each phrased as a constraint plus its reason.
- **Excuse**: one `gh issue create` per fix, naming the location, what the comment excused and the fix that makes it unnecessary; sites that share a fix share an issue.

ADRs and issues travel beyond the code: keep secrets, private hostnames and personal data out.

Done when every decision record is in an ADR and every excuse in an issue.

## 5. Delete
A file where every comment goes: `ast-grep scan --update-all <file>`. Always pass paths; a bare run also strips vendored and generated files. A file with keeps: delete the rest by hand. Then `just fix` formats and lowers the baseline.

Done when `ast-grep scan <scope>` lists only keeps.

## 6. Gate and report
`just check` passes and the baseline diff only shrinks. Report blocks per label, ADRs touched, issues filed, comment lines removed, and comment lines left repo-wide (sum of `range.end.line - range.start.line + 1` over `ast-grep scan --json=stream`).
