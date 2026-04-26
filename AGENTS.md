# AGENTS

## Source Of Truth
- This repo is a `flake-parts` flake with `import-tree ./modules` in `flake.nix`. Every `.nix` file under `modules/` is loaded automatically; do not add scratch files there.
- The active config is the dendritic tree under `modules/aspects/`. Prefer editing those files over anything in `modules/hosts/` except `modules/hosts/tester/default.nix`.
- `modules/hosts/tester/configuration.nix` and `modules/hosts/tester/hardware.nix` are currently empty stubs. Do not put real config back there.

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
- `nix build .#nixosConfigurations.tester.config.system.build.toplevel --dry-run`

## Known Wiring
- The only exported NixOS host is `nixosConfigurations.tester` from `modules/hosts/tester/default.nix`.
- `modules/aspects/host/tester.nix` currently imports `tester-hardware`, `home-manager`, `identity-ph`, `niri`, and `workstation`.
- `modules/aspects/identity/ph.nix` is also the standalone Home Manager entrypoint via `flake.homeConfigurations.ph`.
