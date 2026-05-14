# AGENTS

## Source Of Truth
- This repo is a `flake-parts` flake with `import-tree ./modules` in `flake.nix`. Every `.nix` file under `modules/` is loaded automatically; do not add scratch files there.
- New files are invisible to `nix flake` evaluation until Git tracks them. If you add a file that must participate in `nix eval`, `nix flake check`, or `nix build`, stage it with `git add <path>` before running verification commands.
- The active config is the dendritic tree under `modules/aspects/`. Prefer editing those files over anything in `modules/hosts/` except the host entrypoint you are wiring.
- `modules/hosts/tester/configuration.nix` and `modules/hosts/tester/hardware.nix` are currently empty stubs. Do not put real config back there.
- `nixosConfigurations.nika` is the primary host. `tester` remains in the repo only as a secondary/scratch host and should not be treated as the default target for fixes, checks, or verification unless the user explicitly asks for it.

## Dendritic Rules
- Keep modules aspect-oriented. Add to an existing aspect before creating a new one.
- Use `flake.modules.nixos.<aspect>` for NixOS aspects and `flake.modules.homeManager.<aspect>` for Home Manager aspects.
- Keep host composition thin. `modules/aspects/host/tester.nix` should select aspects, not hold feature details.
- Put user-specific wiring in `modules/aspects/identity/ph.nix`.
- Put WM-specific logic in `modules/aspects/desktop/<wm>.nix`. `niri` is the current selected WM; a future `hyprland.nix` should be a parallel module, not mixed into `niri.nix`.
- Keep shared desktop tools separate from the WM module when they are reusable across WMs.
- `modules/parts.nix` imports flake-parts' `modules` extra. `nix flake check` warns `unknown flake output 'modules'`; this is expected here.

## Dendritic References
- `https://dendrix.oeiuwq.com/Dendritic.html`
- `https://dendrix.oeiuwq.com/Dendrix-Conventions.html`
- `https://www.vimjoyer.com/nix`

## Layout
- `modules/aspects/integration/home-manager.nix`: imports/configures Home Manager for NixOS.
- `modules/aspects/identity/ph.nix`: user account, HM imports, standalone `homeConfigurations.ph`.
- `modules/aspects/cli/`: CLI aspects (`git.nix`, `nushell.nix`).
- `modules/aspects/desktop/`: desktop aspects (`niri.nix`, `noctalia.nix`, `ghostty.nix`, `cursor.nix`).
- `modules/aspects/host/`: host composition (`tester.nix`, `tester-hardware.nix`, `workstation.nix`).

## Verification
- Always run both after changes:
- `nix flake check`
- `nix build .#nixosConfigurations.nika.config.system.build.toplevel --dry-run`

## Known Wiring
- The primary exported NixOS host is `nixosConfigurations.nika` from `modules/hosts/nika/default.nix`.
- `modules/aspects/host/nika.nix` currently imports `nika-hardware`, `audio-output`, `home-manager`, `identity-ph`, `handy`, `openhome`, `openlinkhub`, `openssh`, `tailscale`, `niri`, `niri-dp1-1080p`, `workstation`, and related desktop aspects.
- `modules/aspects/host/tester.nix` still exists, but it is not the default host target.
- `modules/aspects/identity/ph.nix` wires the `ph` user through Home Manager inside the NixOS hosts.
