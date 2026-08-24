# AGENTS

## Source Of Truth
- This repo is a `flake-parts` flake with `import-tree ./modules` in `flake.nix`. Every `.nix` file under `modules/` is loaded automatically; do not add scratch files there.
- New files are invisible to `nix flake` evaluation until Git tracks them. If you add a file that must participate in `nix eval`, `nix flake check`, or `nix build`, stage it with `git add <path>` before running verification commands.
- The active config is the dendritic tree under `modules/aspects/`. Prefer editing those files over anything in `modules/hosts/` except the host entrypoint you are wiring.
- `nixosConfigurations.nika` is the primary desktop host. `zaza` is the headless k3s homelab host. `imu` is the WSL host. Do not default to `nika` for unrelated fixes or verification unless the change is desktop-specific; use the host relevant to the change.

## Dendritic Rules
- Keep modules aspect-oriented. Add to an existing aspect before creating a new one.
- Use `flake.modules.nixos.<aspect>` for NixOS aspects and `flake.modules.homeManager.<aspect>` for Home Manager aspects.
- In Home Manager aspects, prefer `programs.<tool>.enable` when the HM option exists; fall back to `home.packages` only when it does not.
- Keep host composition thin. `modules/aspects/host/zaza.nix` should select aspects, not hold feature details.
- Put user-specific wiring in `modules/aspects/identity/ph.nix`.
- Put WM-specific logic in `modules/aspects/desktop/<wm>.nix`. `niri` is the current selected WM; a future `hyprland.nix` should be a parallel module, not mixed into `niri.nix`.
- Keep shared desktop tools separate from the WM module when they are reusable across WMs.
- `modules/parts.nix` imports flake-parts' `modules` extra. `nix flake check` warns `unknown flake output 'modules'`; this is expected here.
- After every implementation, ask: is the dendritic pattern implemented correctly? If not, redo the implementation.

## Dendritic References
- `https://dendrix.oeiuwq.com/Dendritic.html`
- `https://dendrix.oeiuwq.com/Dendrix-Conventions.html`
- `https://www.vimjoyer.com/nix`

## Layout
- `modules/aspects/integration/home-manager.nix`: imports/configures Home Manager for NixOS.
- `modules/aspects/identity/ph.nix`: user account, HM imports, standalone `homeConfigurations.ph`.
- `modules/aspects/cli/`: CLI aspects (`git.nix`, `nushell.nix`).
- `modules/aspects/desktop/`: desktop aspects (`niri.nix`, `noctalia.nix`, `ghostty.nix`, `cursor.nix`).
- `modules/aspects/host/`: host composition (`nika.nix`, `zaza.nix`, `imu.nix`, `zaza-hardware.nix`, `workstation.nix`).
- `modules/aspects/homelab/`: homelab service aspects (`k3s.nix`, `traefik.nix`, `excalidraw.nix`, `searxng.nix`, `hermes.nix`).

## Verification
- Run validation from the repository root using the root `justfile`. With direnv enabled, `.envrc` loads the flake dev shell and provides `just`.
- After every implementation, run `just verify <host>`. It formats the repository, runs Statix, runs `nix flake check`, and performs the host build dry run.
- Use the host relevant to the change, not the desktop host by default. Use `just check` only when no NixOS host is relevant; it runs formatting, Statix, and `nix flake check` without a host build.

## Known Wiring
- The primary exported NixOS host is `nixosConfigurations.nika` from `modules/hosts/nika/default.nix`.
- `modules/aspects/host/nika.nix` currently imports `nika-hardware`, `audio-output`, `home-manager`, `identity-ph`, `handy`, `openhome`, `openlinkhub`, `openssh`, `tailscale`, `niri`, `niri-dp1-1080p`, `workstation`, and related desktop aspects.
- `modules/aspects/host/zaza.nix` wires the headless k3s homelab host.
- `modules/aspects/host/imu.nix` wires the WSL host.
- `modules/aspects/identity/ph.nix` wires the `ph` user through Home Manager inside the NixOS hosts.
