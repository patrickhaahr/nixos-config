# nixos-config

> *"Reproducibility is not a bug—it is the whole operating system."*

A personal NixOS flake built around the **dendritic pattern**: thin host entrypoints, rich aspect-oriented modules. One machine, one user, infinite recombination.

The primary host is named **nika** — after the Sun God Nika, the liberator of joy from *One Piece*.

---

## The Dendrite

Instead of monolithic host files that rot, this configuration grows like a crystal. Behavior is split into **aspects**—self-contained facets of a system (desktop, shell, identity, hacking)—and hosts are merely thin compositions of those aspects.

- **Host composition** is minimal: pick your hardware, pick your aspects, done.
- **User identity** is an aspect. **Window manager** is an aspect. **Security tooling** is an aspect.
- Everything under `modules/` auto-registers via `flake-parts` + `import-tree`.

If an aspect does not exist, you grow a new one. You never bolt features into a host file.

---

## The Pantheon

The gods of this system are named after the divine of *One Piece*. Each host is a deity with its own domain.

### ☀️ `nika` — The Sun God

The primary desktop. Copenhagen timezone, Danish keys, AMD silicon, encrypted root, and Secure Boot locked down with Lanzaboote.

- **Niri** — a scrollable Wayland compositor, wrapped and bound to custom logic.
- **Noctalia** — the ambient shell / desktop UI layer that glides over Niri.
- **Ghostty** — the terminal.
- **Helium** — the browser.
- **Handy** — always within reach.
- **Signal**, **Spotify** (with Spicetify), **Steam**, **Sunshine** — communication, sound, and play.
- **OpenHome** — IR bridge to the physical world; Bluetooth on boot, Optical on shutdown.
- **OpenLinkHub** — local hardware state daemon.
- **Tailscale** — the private mesh.

### 🌧️ `zaza` — The Rain Goddess

The headless k3s homelab host. Where the sun does not reach, the rain brings life. Zaza is the cloud beneath the cloud—running Kubernetes, hosting services, and serving the home from a quiet corner.

- **k3s** — the Kubernetes raincloud, orchestrating containers like droplets in a storm.
- **Traefik** — the divine gateway; all traffic flows through the Rain God's river, with TLS carried by Cloudflare.
- **SearXNG** — a private, meta-search engine tuned to the user's will (dark mode, vim keys, curated engines, and a Danish default).
- **Excalidraw** — the whiteboard of the gods, for sketching ideas in the clouds.
- **Hermes** — the messenger. Nous Research's agent gateway and dashboard, wired into Signal and an internal API. The homelab thinks, and it speaks.
- **OpenSSH** — the tunnel into the storm.
- **SOPS** — secrets are sealed with weather magic.
- **Tailscale** — the private mesh, even in the rain.

### 👁️ `imu` — The King of the World

A WSL host. The secret ruler who sits on the Empty Throne. The only one of the pantheon who does not touch bare metal, but instead floats above it—inside the abstraction of Windows, unseen, pulling strings from the shadows.

Imu carries the minimal identity of the user: Nushell, Home Manager, and the **agent-browser** skill for AI-driven browsing. Nothing more. No desktop, no sound, no sun. Just the quiet observation of a hidden supreme ruler.

---

## Shell: Noctalia + Nushell

The login shell is **Nushell**, armed with Starship, zoxide, and carapace. It is not Bash. It is not Zsh. It is structured data all the way down.

Noctalia wraps the desktop experience—wallpaper caching, GTK dark mode defaults, and the visual logic that makes Niri feel alive.

---

## Agents

This system is co-piloted by AI agents. The configuration ships with **OpenCode** fully wired:

- **AGENTS.md** — the local source of truth for agent behavior and dendritic rules.
- **Skills** — local custom skills plus a **skill-sources** pipeline that imports and keeps up-to-date popular skills from the community.
  - *External providers:* `grill-me`, `improve-codebase-architecture`, `tdd`, `agent-browser`, `frontend-design`, and more.
  - *Local skills:* code standards for **C#**, **Rust**, and **TypeScript**.
- **Agents** — sub-agent definitions for specialized tasks, including a **reviewer** and a **simplifier**.
- **Plugins & Commands** — extended toolchains that agents can invoke.

Agents operate with full context of the dendritic layout. They know: *edit the aspect, not the host*.

---

## Hacking Arsenal

These tools live in the repo as dormant aspects—ready to be grafted onto any host when the red team calls:

- **Recon:** `nmap`, `ffuf`, `feroxbuster`
- **Web:** `burpsuite`
- **Cracking:** `hashcat`, `hydra`, `john`
- **Forensics:** `binwalk`, `exiftool`
- **Network:** `wireshark`, `wireguard-tools`
- **Wordlists:** `rockyou`, guides, and docs mapped to `~/hacking`

Currently disarmed on `nika`, but one uncomment away.

---

## Notable Tooling

| Category | Stack |
|---|---|
| **Editor** | Neovim |
| **Terminal** | Ghostty |
| **Shell** | Nushell + Starship |
| **Navigation** | yazi, fzf, zoxide |
| **Env** | direnv + nix-direnv |
| **Orchestration** | k3s + Traefik |
| **Secrets** | SOPS + sops-nix |

---

## Build

```bash
# Evaluate the flake
nix flake check

# Dry-run the primary system
nix build .#nixosConfigurations.nika.config.system.build.toplevel --dry-run

# Dry-run the rain goddess
nix build .#nixosConfigurations.zaza.config.system.build.toplevel --dry-run

# Dry-run the hidden ruler
nix build .#nixosConfigurations.imu.config.system.build.toplevel --dry-run
```

---

*Built with ❄️ and paranoia.*
