# Package and platform constraints

Constraints imposed by upstream packages or by NixOS itself, which the code works around and which would otherwise look like needless overrides.

- **bun** comes unpatched from llm-agents.nix (`bun-bin`), which tracks upstream releases: nixpkgs' patchelf'd bun (>= 1.3.14) miscompares its own runtime image and emits segfaulting `bun build --compile` output. `bun-bin` ships its binary under `share/bun-bin/` with no `bin/`, so the aspect symlinks it as the CLI.
- **T3 Code** native server modules are built for Node, not Electron's ABI, so the desktop app is patched to spawn its server with Node instead of its own executable. Its login-shell PATH probe uses POSIX syntax, which Nushell cannot parse, so its binaries are wrapped with `SHELL` set to bash. The Electron product name is pinned to "T3 Code (Alpha)": safeStorage derives its keyring key from that name, and upstream's rename to "(Beta)" would strand the encrypted connection catalog. llm-agents' t3code installs only `out` (the CLI) via `outputsToInstall`, so the desktop output is added explicitly. On zaza a hermes user service stands in for `t3 service install`, because `t3 service` and `t3 update` install unmanaged downloaded releases; the user's linger keeps it alive across logout.
- **Kaigen Studio** loads HTTPS support with `dlopen`, so ELF scanning cannot find OpenSSL; its toolchain install shells out to tar, so decompressors are on its PATH; its engine scans only FHS font paths, so tmpfiles exposes the shipped fonts at one of them.
- **AppImages** wrapped with `wrapType2` expose only `bin/`, so learnharness extracts again to ship its `.desktop` entry and icon.
- **computer-use-linux** skips the ydotool probe test, which needs a short private temp path the Nix sandbox cannot provide.
- **Helium** is wrapped with the Vulkan loader and the system driver manifests, which it needs for native WebGPU.
- **Hex** follows this flake's nixpkgs, so its libc stays compatible with the host's Vulkan drivers.
- **Codex** (also the copy bundled with T3 Code) gets OpenSSL as a build input: nixpkgs' aws-lc dropped its compat `openssl.pc` and prefixes its symbols, so openssl-sys needs real OpenSSL until llm-agents adapts.
- **ffmpeg** includes libx264 because T3 Code's Android video stream needs it; T3 Code finds `avdmanager` only under `cmdline-tools/latest`.
- **Echo Dot** unlock and flashing over USB uses a packaged udev rules file, not `extraRules`: `uaccess` applies only before `73-seat-late.rules`, and `extraRules` lands in `99-local.rules`.
- **OpenSSH** rejects store-owned config for non-root users: systemd's ssh proxy drop-in is disabled, and hermes' ssh client config is installed as an owned file rather than a store symlink. Hosts without Ghostty's terminfo get `TERM=xterm-256color` instead of `xterm-ghostty`.
- **Bash** in an interactive ssh session starts as a login shell and reads `.bash_profile`, not `.bashrc`, which is the only file the Home Manager config fills, so `.bash_profile` sources `.bashrc`.
- **Noctalia** v5 reads TOML; the v4 JSON files are kept for rollback but not loaded.
- **niri** binds both modifier orders, because the last modifier pressed becomes the keysym.
- **Kernel module locking**: nika sets `security.lockKernelModules`, so the modules Docker and Bluetooth gamepads need are listed in `boot.kernelModules` to load at boot, before the lock. `sd_mod` is listed too, because nika's kernel does not auto-load it for USB card readers.
- **Raspberry Pi (vivi)**: the default 512 MiB CMA reservation fails on the 2 GB Pi 4, so vivi reserves 128 MiB, and rpicam-apps expects the Raspberry Pi OS alias for the CMA heap, so udev adds it. nika builds vivi under aarch64 binfmt emulation but trusts the nixos-raspberrypi caches: the Pi packages are not on cache.nixos.org, and rebuilding them emulated is slow and trips stale upstream source hashes.
- **Shutdown jobs**: start jobs are cancelled during the shutdown transaction, so the OpenHome IR command at shutdown runs from `ExecStop` of a `RemainAfterExit` oneshot ordered before `shutdown.target` and after `network.target`, so it stops before the network does.
- **Nix GC** runs inline once free space drops below `min-free`, so builds between scheduled runs cannot fill the disk.
- **nix-daemon** fetches GitHub for flake updates and hits the anonymous rate limit without a token, so sops renders an `access-tokens` line into its environment.
- **sops-nix** creates a missing secret parent directory as root, so the canary declares `~/.aws` with tmpfiles, owned by the user.
- **Hermes GPT-Live**: the GPT-Live (`live`) extra for hermes-talk adds aiortc and the packages the sealed venv lacks. Their Python dependencies are build-only, because av, cryptography and cffi come from the venv at run time and propagating them again fails the module's collision check; C libraries (libsrtp, openssl) stay host inputs so their headers and rpath reach the extension.
