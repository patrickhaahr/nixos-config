---
name: commit
description: Expert guide for writing git commit messages following the Conventional Commits 1.0.0 specification.
---

## Overview
This skill ensures that all git commit messages adhere strictly to the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification. This convention creates an explicit commit history that is easy to read and automate.

## Workflow
**CRITICAL**: Before drafting any commit message, you MUST perform the following steps to ensure context and accuracy:

1.  **Analyze Changes**: Run `git diff` (and `git diff --staged` if applicable) to fully understand *what* is being changed.
2.  **Check History**: Run `git log -n 5` (or similar) to review recent commit messages. This helps you:
    *   Match the existing project style/convention.
    *   Understand the context of recent work.
3.  **Draft Message**: detailed below.

### Guideline on User-Facing Descriptions
**PREFER TO EXPLAIN WHY FROM THE END USER PERSPECTIVE, NOT WHAT WAS DONE.**

*   **BE SPECIFIC**: Generic messages like "improved agent experience" or "enhanced functionality" are unacceptable. State exactly what the user can now do or how their experience changed.
*   **FOCUS ON IMPACT**: Explain what changed for the user, not what code was modified. A user should understand the value of this commit without reading code.
*   **GOOD EXAMPLES**:
    *   `fix: allow users to retry failed uploads without losing progress`
    *   `feat: add dark mode toggle to settings page`
    *   `fix: display error messages in user's preferred language`
*   **BAD EXAMPLES**:
    *   `feat: improve agent experience` (vague, no specific user impact)
    *   `fix: enhanced error handling` (what does this mean for users?)
    *   `refactor: improved backend logic` (implementation detail, not user-facing)

### Guideline on Conciseness
**PREFER CONCISE ONE-LINERS**.
*   In 80-90% of cases, the subject line is sufficient.
*   **DO NOT** add a body if the subject line explains the change clearly.
*   **DO NOT** write a body that just repeats the subject line in bullet points.
*   **ONLY** add a body for complex architectural changes, obscure bug fixes requiring "why" context, or detailed Breaking Change explanations.

## Commit Message Format
The message MUST be structured as follows:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 1. Type (Required)
Must be one of the following:
*   **`feat`**: Introduces a new feature (correlates with MINOR in SemVer).
*   **`fix`**: Patches a bug (correlates with PATCH in SemVer).
*   **`build`**: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm).
*   **`chore`**: Other changes that don't modify src or test files.
*   **`ci`**: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs).
*   **`docs`**: Documentation only changes.
*   **`style`**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc).
*   **`refactor`**: A code change that neither fixes a bug nor adds a feature.
*   **`perf`**: A code change that improves performance.
*   **`test`**: Adding missing tests or correcting existing tests.

### 2. Scope (Optional)
A noun describing a section of the codebase, surrounded by parenthesis.
*   Example: `feat(parser): add ability to parse arrays`
*   Example: `fix(api): handle empty response`

### 3. Description (Required)
A short summary of the code changes immediately following the colon and space.
*   Use the imperative, present tense: "change" not "changed" or "changes".
*   Don't capitalize the first letter.
*   No dot (.) at the end.

### 4. Body (Optional)
**Avoid unless necessary.** Use only if the description is not enough to explain the *what* and *why* of a complex change.
*   Must be separated from the description by a blank line.
*   Can have multiple paragraphs.

### 5. Breaking Changes (Important)
If the commit introduces a breaking API change (correlates with MAJOR in SemVer):
*   **Option A**: Add `!` after the type/scope.
    *   Example: `feat!: send an email to the customer`
    *   Example: `feat(api)!: send an email to the customer`
*   **Option B**: Add a footer starting with `BREAKING CHANGE:` followed by a space and description.
    *   Example:
        ```text
        chore: drop support for Node 6

        BREAKING CHANGE: use JavaScript features not available in Node 6.
        ```

### 6. Footers (Optional)
Follow the git trailer format.
*   `Reviewed-by: Z`
*   `Refs: #123`

## Examples

**Standard Feature:**
```text
feat: allow provided config object to extend other configs
```

**Standard Fix:**
```text
fix: prevent racing of requests
```

**Breaking Change (with !):**
```text
feat!: send an email to the customer when a product is shipped
```

**Breaking Change (with footer):**
```text
chore!: drop support for Node 6

BREAKING CHANGE: use JavaScript features not available in Node 6.
```

**Documentation:**
```text
docs: correct spelling of CHANGELOG
```
