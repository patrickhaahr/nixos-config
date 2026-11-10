# AGENTS

## Source Of Truth
- This repo is a `flake-parts` flake with `import-tree ./modules` in `flake.nix`. Every `.nix` file under `modules/` is loaded automatically; do not add scratch files there.
- New files are invisible to `nix flake` evaluation until Git tracks them. Stage a new file with `git add <path>` before `nix eval`, `nix flake check`, or `nix build`.
- The active config is the dendritic tree under `modules/aspects/`. Prefer editing those files over anything in `modules/hosts/` except the host entrypoint you are wiring.
- Hosts: `nika` is the desktop, `zaza` the headless k3s homelab running Hermes and T3 Code as the `hermes` user, `imu` the WSL host. Use the host relevant to the change, not `nika` by default.

## Dendritic Rules
- Keep modules aspect-oriented. Add to an existing aspect before creating a new one.
- Use `flake.modules.nixos.<aspect>` for NixOS aspects and `flake.modules.homeManager.<aspect>` for Home Manager aspects.
- In Home Manager aspects, prefer `programs.<tool>.enable` when the HM option exists; fall back to `home.packages` only when it does not.
- Keep host composition thin. `modules/aspects/host/<host>.nix` selects aspects and holds no feature details.
- Put user-specific wiring in `modules/aspects/identity/<user>.nix`. Tools every agent user needs go in the `agent-tools` aspect.
- Put WM-specific logic in `modules/aspects/desktop/<wm>.nix` (`niri` today). Shared desktop tools stay out of the WM module.
- Hermes hosts compose through the `agent-hermes-host` seam in `modules/aspects/agent/hermes/host.nix`.
- External skills are listed in `agents/skill-sources/sources.nix` and sparse-fetched, never added as flake inputs (an input downloads the whole repo). After changing an entry, run `just update-skills <owner/repo>`; only that recipe writes `sources.lock.json`.
- `modules/aspects/agent/browser-use/` vendors a `uv.lock`; regenerate it with `uv lock --python 3.12` when bumping.
- `nix flake check` warns `unknown flake output 'modules'`; this is expected here.
- After every implementation, ask: is the dendritic pattern implemented correctly? If not, redo the implementation.
- References: https://dendrix.oeiuwq.com/Dendritic.html, https://dendrix.oeiuwq.com/Dendrix-Conventions.html

## Verification
- After every implementation, run `just verify <host>` from the repository root. It formats, runs Statix and `nix flake check`, and dry-runs the host build. Use `just check` when no host is relevant.
- `just switch` needs the user's password on nika. Hand the user the command and report the change as built, not activated.
