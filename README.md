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

## The Machine: `nika`

The primary system. Copenhagen timezone, Danish keys, AMD silicon, encrypted root, and Secure Boot locked down with Lanzaboote.

**What she runs:**
- **Niri** — a scrollable Wayland compositor, wrapped and bound to custom logic.
- **Noctalia** — the ambient shell / desktop UI layer that glides over Niri.
- **Ghostty** — the terminal.
- **Helium** — the browser.
- **Handy** — always within reach.
- **Signal**, **Spotify** (with Spicetify), **Steam**, **Sunshine** — communication, sound, and play.
- **OpenHome** — IR bridge to the physical world; Bluetooth on boot, Optical on shutdown.
- **OpenLinkHub** — local hardware state daemon.
- **Tailscale** — the private mesh.

`zaza` exists as the headless Intel homelab host, but `nika` is the source of truth for desktop changes.

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

---

## Build

```bash
# Evaluate the flake
nix flake check

# Dry-run the primary system
nix build .#nixosConfigurations.nika.config.system.build.toplevel --dry-run
```

---

*Built with ❄️ and paranoia.*
