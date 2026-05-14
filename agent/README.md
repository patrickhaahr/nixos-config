This directory holds source files that are projected into AI tool config directories.

For OpenCode, the contents of `agent/` are projected into
`~/.config/opencode/` by `modules/aspects/cli/opencode.nix`.

`opencode.json` itself is generated from Nix in that module.

`agent/skills` remains the source for local custom skills.

External skill providers are configured under `agent/skill-sources/`. Each provider gets
its own `.nix` file there, and `default.nix` merges them into the final OpenCode skills
directory.
