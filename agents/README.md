This directory is projected to `~/.agents/` as the shared source of AI tool
resources.

OpenCode uses `OPENCODE_CONFIG_DIR=~/.agents` and Pi natively discovers
`~/.agents/skills/`. Pi-specific configuration remains under `~/.pi/agent/`.

`opencode.json` itself is generated from Nix in that module.

`agents/skills` remains the source for local custom skills.

External skill providers are configured under `agents/skill-sources/`. Each provider gets
its own `.nix` file there, and `default.nix` merges them into the final OpenCode skills
directory.

Agent files under `agents/agents/` are shared by OpenCode and Pi. Keep shared
frontmatter limited to fields accepted by both runtimes. Express runtime-specific
capability restrictions in separate runtime configuration rather than mixing their
frontmatter schemas in these files.
