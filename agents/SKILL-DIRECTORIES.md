# Agent Skill Directories

Researched 2026-07-18 against first-party documentation.

Use the plural shared directory, `~/.agents/skills`, for skills intended to be
available to both Pi and current OpenCode. Neither tool documents support for
the singular `~/.agent/skills`.

| Harness | Native global directory | Shared global directory | Project directories |
| --- | --- | --- | --- |
| Pi | `~/.pi/agent/skills/` | `~/.agents/skills/` | `.pi/skills/`, `.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` | `~/.agents/skills/` | `.opencode/skills/`, `.agents/skills/` |

## Pi

Pi's [Skills documentation](https://pi.dev/docs/latest/skills#locations) lists
`~/.pi/agent/skills/` and `~/.agents/skills/` as global locations. It lists
`.pi/skills/` and `.agents/skills/` as project locations, with project skills
requiring project trust.

The default native path is corroborated by Pi's
[`config.ts`](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/src/config.ts),
which constructs the agent configuration directory from `~/.pi/agent`.
`PI_CODING_AGENT_DIR` can override that native base directory.

## OpenCode

OpenCode's [Skills documentation](https://opencode.ai/docs/skills#place-files)
lists `~/.config/opencode/skills/<name>/SKILL.md` as its native global path and
`~/.agents/skills/<name>/SKILL.md` as its agent-compatible global path. The
same document's [discovery section](https://opencode.ai/docs/skills#understand-discovery)
lists `.opencode/skills/`, `.claude/skills/`, and `.agents/skills/` as project
locations discovered while walking to the Git worktree.

The agent-compatible OpenCode path was documented upstream in commit
[`5aaf8f8`](https://github.com/anomalyco/opencode/commit/5aaf8f82475c84640ab5f03caf7fffda4b0ffc9f).
Older OpenCode versions may therefore not discover `.agents` paths.

## Repository Convention

This repository keeps source-managed shared resources under `agents/`, then
projects them to `~/.agents/`. OpenCode uses that directory through
`OPENCODE_CONFIG_DIR`, and Pi natively discovers its `skills/` directory. See
[agents/README.md](README.md).
