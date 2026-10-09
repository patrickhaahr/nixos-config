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
- `modules/aspects/cli/`: CLI aspects (`git.nix`, `nushell.nix`, `agent-browser.nix`).
- `modules/aspects/agent/`: agent aspects. `agent/hermes/` is the hermes sub-aspect (package, config, secrets, channels, git, dev-workspace); compose hosts via its `host.nix` seam (`agent-hermes-host`). `agent/t3code.nix` runs T3 Code as a hermes user service behind traefik at `t3code.zaza.haahr.me` (`nixos.t3code-service` wires the HM unit + k3s ingress). `agent/browser-use/` packages the Browser Use CLI with uv2nix (vendored uv.lock; regenerate with `uv lock --python 3.12` when bumping).
- `modules/aspects/desktop/`: desktop aspects (`niri.nix`, `noctalia.nix`, `ghostty.nix`, `cursor.nix`).
- `modules/aspects/host/`: host composition (`nika.nix`, `zaza.nix`, `imu.nix`, `zaza-hardware.nix`, `workstation.nix`).
- `modules/aspects/homelab/`: homelab service aspects (`k3s.nix`, `traefik.nix`, `excalidraw.nix`, `searxng.nix`; hermes itself lives under `modules/aspects/identity/hermes.nix` + `modules/aspects/agent/hermes/`).

## Verification
- Run validation from the repository root using the root `justfile`. With direnv enabled, `.envrc` loads the flake dev shell and provides `just`.
- After every implementation, run `just verify <host>`. It formats the repository, runs Statix, runs `nix flake check`, and performs the host build dry run.
- Use the host relevant to the change, not the desktop host by default. Use `just check` only when no NixOS host is relevant; it runs formatting, Statix, and `nix flake check` without a host build.

## Known Wiring
- The primary exported NixOS host is `nixosConfigurations.nika` from `modules/hosts/nika/default.nix`.
- `modules/aspects/host/nika.nix` currently imports `nika-hardware`, `audio-output`, `home-manager`, `identity-ph`, `handy`, `openhome`, `openlinkhub`, `openssh`, `tailscale`, `niri`, `niri-dp1-1080p`, `workstation`, and related desktop aspects.
- `modules/aspects/host/zaza.nix` wires the headless k3s homelab host via `agent-hermes-host`, which chains `identity-hermes` → the hermes Home Manager aspect imports (including `agent-browser-use`).
- `modules/aspects/host/imu.nix` wires the WSL host.
- `modules/aspects/identity/ph.nix` wires the `ph` user through Home Manager inside the NixOS hosts.

## Android gadget on zaza

- SDK source: `/home/hermes/dev/hermes-gadget-sdk`, fork branch `android/client`. The gateway loads a plain plugin copy in `~/.hermes/plugins/gadget`; source-checkout edits alone do not deploy it. For Python changes, copy `plugin/*.py` there and restart `hermes-agent` after accepted tasks have finished. `hermes plugins install` currently fails in the Nix package. Live Voice is a separate checkout in `~/.hermes/plugins/talk-desktop`.
- `gadget.nix` enables subscription calls, but the phone chooses what a wake does. **Hermes voice** remains the default; **Live voice** must be selected on the phone. Host configuration does not override that choice, and a failed call never falls back. See the SDK's `docs/android.md` and `docs/hardware-validation.md` for controls and measured limits.
- Build Android from the SDK root with `devenv shell -- bash -c 'cd android && ./gradlew assembleDebug'`. The root `.android` debug key matches the installed gadget. Install with `adb install -r`; never uninstall or run `connectedAndroidTest`, which removes identity/device-owner state. Wireless ADB changes ports and turns off on reboot; `10.0.10.156:39859` was used on 2026-10-09. The gadget URL is normally `ws://10.0.10.3:8765/gadget`, independent of ADB.
- `just switch` restarts both Hermes user services. Do not use it merely to select the phone's voice mode or install an APK, especially while accepted tasks run. For actual backend/configuration changes, follow verification and deployment as usual, then verify the paired phone reconnects.
- Tailscale (SDK issue #9): the phone can reach the gateway at `ws://zaza.taila757c4.ts.net:8765/gadget` with its Tailscale VPN on; the `tailscale0` firewall rule in `gadget.nix` admits it with the existing pairing. Live calls over the tailnet need the SDK's fix for Tailscale's non-bypassable VPN (`android/client` after PR #17). With the VPN on, `10.0.10.0/24` goes through the `pi` subnet router, so use the tailnet name rather than the LAN address. Its normal setup is LAN with Tailscale off. No host setting differs between the two paths.
