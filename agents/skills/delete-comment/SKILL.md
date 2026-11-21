---
name: delete-comment
description: Classify a repo's code comments, move decisions into ADRs and hacks into issues, delete them, and lower the comment ratchet. Optional path narrows the scope.
disable-model-invocation: true
---

# Delete comments

`tools/comment-guard` is a ratchet: `tools/comment-baseline` counts the comment lines each file still holds, and counts only fall. The **scope** is the paths the user names, else the whole repo. One run drives the scope to the floor without losing what the comments knew.

## 1. Guard
No `tools/comment-guard` yet: read `~/.agents/skills/setup-repo/SKILL.md` (manual-only, so read the file), copy `sgconfig.yml`, `tools/ast-grep/` and `tools/comment-guard` from its `templates/common/`, and follow its "Align an existing repo" section.

Done when `just check` runs the guard and `tools/comment-baseline` exists.

## 2. Slice
A **slice** is a list of files from `tools/comment-baseline` (vendored and generated files never appear there), holding roughly 300 comment lines and cut along directory lines: split a large directory by subdirectory, merge small siblings, and put every file in exactly one slice. Note the scope's total from the baseline. Create a branch.

Done when every file in the scope with a baseline count belongs to one slice.

## 3. Work the slices
One slice: follow [slice.md](slice.md) yourself. Several: dispatch one subagent per slice (volume work: Sonnet), all in parallel, each told to read `slice.md` in this skill's directory and given its slice files. Check each reply against its diff: every deletion is labelled, only comments left the code, and decision records and excuses name real lines.

Done when every slice has returned its four sections and its files hold only keeps.

## 4. Move
- **Decision records**: into the repo's ADR directory (`docs/adr/` when none exists) in the **domain-modeling** skill's format. Group by theme across slices, extend an existing ADR on that theme, drop records existing docs already state, and phrase each as a constraint plus its reason. Many themes: dispatch one drafting subagent per area (judgment work: Opus) and number the drafts yourself.
- **Excuses**: one `gh issue create` per fix, merging slices that report the same fix.

ADRs and issues travel beyond the code: keep secrets, private hostnames and personal data out.

Done when every decision record is in an ADR and every excuse in an issue.

## 5. Review the ADRs
Dispatch one fresh reviewer per area (judgment work: Opus; never an ADR's author), each given the new ADRs and appends for its area. A reviewer checks every claim against the code, fixes wrong claims in place, deletes bullets that other docs already cover, removes private data, and reports code that contradicts an ADR. File each contradiction as an issue.

Done when every new ADR and append has been reviewed and every contradiction is an issue.

## 6. Gate and report
Run `just check` (it formats and lowers the baseline). Commit the deletions with the baseline, then the ADRs. Report blocks per label, ADRs touched, claims the reviewers fixed, issues filed, comment lines removed, and comment lines left repo-wide (the baseline's sum).

Done when `just check` passes and the baseline diff only shrinks.
