# Delete the comments in one slice

You own the files listed in your slice and no others. Classify every comment in it, delete what goes, and return what the comments knew; the caller writes the ADRs and issues and runs the gate.

## 1. Inventory
`ast-grep scan --json=stream <slice files>` prints one JSON line per comment (`file`, `range`, `text`). Group adjacent own-line comments into one **block**.

Done when every block in the slice is on your list.

## 2. Classify
Read each block with the code it sits on and give it one label:

- **Tautology**: restates the names, types or control flow, including banners, closing-brace labels and docs that paraphrase a signature.
- **Stale**: describes code or behaviour that is gone, or repeats a source of truth kept elsewhere (an ADR, `docs/`, a skill, a config).
- **Excuse**: covers for a shortcut. Scent: `IMPORTANT`, `do not remove`, `for now`, `hack`, `workaround`, a long justification, tuple fields named only in prose, magic numbers derived in prose, a lifecycle explained instead of modelled, a rule kept "in step with" another copy, or a suppression of a rule that guards correctness.
- **Decision record**: a constraint the code cannot show, such as a platform quirk, a security invariant, a protocol limit or why an alternative lost.

**Keeps** sit outside the labels and stay:

- Doc comments the program reads: clap `--help`, schema descriptions, Rust doctests. Shrink them by moving the text into attributes (`#[arg(help = "...")]`, `#[schemars(description = "...")]`) or the doctest into a unit test, with the output unchanged.
- Licence notices the guard's pattern missed.
- Files a tool checksums, such as applied migrations.

Done when every block has a label and a few-word reason.

## 3. Delete
A file where every comment goes: `ast-grep scan --update-all <file>`. Always pass file paths; a bare run strips files outside your slice. A file with keeps: delete the rest by hand. Leave formatting, the baseline, ADRs and issues to the caller.

Done when `ast-grep scan <slice files>` lists only keeps.

## 4. Return
Reply with exactly these sections:

- **Counts**: blocks per label, keeps, and comment lines deleted.
- **Decision records**: one per record: `path:line`, a theme in two or three words, and the constraint plus its reason in one or two sentences.
- **Excuses**: one per fix: every `path:line` it covers, what the comment excused, and the fix that makes it unnecessary.
- **Keeps**: `path:line` and the reason.
