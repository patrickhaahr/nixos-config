# AGENTS

## Source Of Truth
- This repo is a `flake-parts` flake with `import-tree ./modules` in `flake.nix`. Every `.nix` file under `modules/` is loaded automatically; do not add scratch files there.
- New files are invisible to `nix flake` evaluation until Git tracks them. Stage a new file with `git add <path>` before `nix eval`, `nix flake check`, or `nix build`.
- The active config is the dendritic tree under `modules/aspects/`. Each host is one file, `modules/aspects/host/<host>.nix`, declaring both `flake.nixosConfigurations.<host>` and the `<host>` aspect it builds.
- Decisions the code cannot show live in `docs/adr/`. Before changing an aspect, read the ADRs that name it; record a new constraint as an ADR there (domain-modeling format), never as a comment.
- Hosts: `nika` is the desktop, `zaza` the headless homelab running Hermes and T3 Code as the `hermes` user, `imu` the WSL host. Use the host relevant to the change, not `nika` by default.

## Dendritic Rules
- Keep modules aspect-oriented. Add to an existing aspect before creating a new one.
- Use `flake.modules.nixos.<aspect>` for NixOS aspects and `flake.modules.homeManager.<aspect>` for Home Manager aspects.
- In Home Manager aspects, prefer `programs.<tool>.enable` when the HM option exists; fall back to `home.packages` only when it does not.
- Keep host composition thin. `modules/aspects/host/<host>.nix` picks the nixpkgs builder, selects aspects and holds no feature details.
- Put user-specific wiring in `modules/aspects/identity/<user>.nix`. Tools every agent user needs go in the `agent-tools` aspect.
- An app whose NixOS aspect has a Home Manager half holding only app settings adds it with `home-manager.sharedModules`, so importing the NixOS aspect brings the whole app to every Home Manager user on that host; never probe its options from an identity. A half that carries a user's secrets or desktop-user apps (ADR 0007) stays in that user's identity aspect.
- An app's keybinds, startup commands and window rules live in the app's own NixOS aspect as `desktop.*` options (`desktop/session.nix`), never in the WM. The WM adapter in `modules/aspects/desktop/<wm>/` (`niri` today) translates them and owns only WM-native settings and binds; see `docs/adr/0007-window-manager-is-a-desktop-session-adapter.md`.
- zaza serves a signed harmonia binary cache over tailscale (`binary-cache-server`); every other host imports `binary-cache` to substitute from it. nika (`binary-cache-builder`) signs what it builds, every host trusts that key, and `just deploy` builds on nika and pushes each closure to zaza.
- Homelab web services declare `services.nginx.virtualHosts."<name>.${config.homelab.domain}"`; `homelab-proxy` sets `homelab.domain` to `<hostName>.haahr.me` and adds that host's wildcard cert and HTTPS. Another host reaches a service through `self.nixosConfigurations.<host>.config.homelab.domain`; read only host-local options that way. Prefer native NixOS service modules; fall back to `virtualisation.oci-containers` (podman) only for software nixpkgs lacks.
- Podman containers join networks through `homelab.podmanNetworks` (import `homelab-podman`) and pin images as `repo:tag@sha256:…`; `just update-images` re-resolves every such tag.
- Agent tooling lives in `modules/aspects/agent/`, grouped by subject rather than CLI or desktop; a tool with several aspects gets a directory (`hermes/`, `t3code/`). The root `agents/` holds only what agents read (instructions, skills, skill sources). Agent instructions and skills reach aspects only through `agent-skills`, which deploys `~/.agents/AGENTS.md` and `~/.agents/skills` and exposes `config.lib.agents.instructions`; `git-guardrails` reads its file-size guard straight from the `setup-repo` skill template.
- Hermes hosts compose through the `agent-hermes-host` seam in `modules/aspects/agent/hermes/host.nix`.
- External skills are listed in `agents/skill-sources/sources.nix` and sparse-fetched, never added as flake inputs (an input downloads the whole repo). After changing an entry, run `just update-skills <owner/repo>`; only that recipe writes `sources.lock.json`.
- A skill pack only one specialist agent uses goes in `agents/skill-sources/bundles.nix` with a role prompt in `agents/specialists/<name>.md`, never in `sources.nix`; see `docs/adr/0008-specialist-agents-own-their-skills.md`.
- Before making a skill manual-only in `agents/skill-sources/overrides.nix`, find the skills that load it: rewrite each reference with `<skill>.replace."<exact text>"` so it reads `~/.agents/skills/<name>/SKILL.md` instead, or leave the skill model-invocable.
- `modules/aspects/agent/browser-use/` vendors a `uv.lock`; regenerate it with `uv lock --python 3.12` when bumping.
- `nix flake check` warns `unknown flake output 'modules'`; this is expected here.
- After every implementation, ask: is the dendritic pattern implemented correctly? If not, redo the implementation.
- References: https://dendrix.oeiuwq.com/Dendritic.html, https://dendrix.oeiuwq.com/Dendrix-Conventions.html

## Verification
- After every implementation, run `just verify <host>` from the repository root. It formats, runs Statix and `nix flake check`, and dry-runs the host build. Use `just check` when no host is relevant.
- `just switch` needs the user's password on nika. Hand the user the command and report the change as built, not activated.
