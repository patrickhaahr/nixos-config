



<p align="center">
  <img src="assets/nixos_logo.png" alt="NixOS logo" width="120" />
</p>

<h1 align="center">nixos-config</h1>

<p align="center">
  A personal NixOS flake built around the <strong>dendritic pattern</strong>: thin host entrypoints, rich aspect-oriented modules.
</p>

> *"Reproducibility is not a bug—it is the whole operating system."*

---

## The Dendrite

Instead of monolithic host files that rot, this configuration grows like a crystal. Behavior is split into **aspects** — self-contained facets of a system (desktop, shell, identity, security, homelab) — and hosts are merely thin compositions of those aspects, grafted onto hardware.

- **Host composition** is minimal: pick your hardware, pick your aspects, done.
- **User identity** is an aspect. **Window manager** is an aspect. **Security tooling** is an aspect. **A Kubernetes cluster** is an aspect.
- Everything under `modules/` auto-registers via `flake-parts` + `import-tree`.

If an aspect does not exist, you grow a new one. You never bolt features into a host file. A branch that breaks this rule is a branch that drifts back into the darkness of imperative sysadmining.

*"Do not argue with the crystal. Listen to it, and it will show you the next facet."*

---

## The Pantheon

The gods of this system are named after the divine and the accursed of *One Piece*. Each host is a deity with its own domain. They are all bound together in a private **Tailscale** tailnet: one mesh, four gods, zero exposed ports.

### ☀️ `nika` — The Sun God

Desktop host burns at 5.7 GHz — sixteen threads drumming the rhythm of liberation. He stretches Niri windows across monitors, bounces Steam and Sunshine through encrypted roots, and casts light where Lanzaboote locks the boot. Signal, Spicetify, and local LLMs run side by side without breaking the smile. Every `nixos-rebuild switch` is Joy Boy's return.

### 🌧️ `zaza` — The Rain Goddess

The headless k3s homelab host. Where the sun does not reach, the rain brings life. Zaza is the cloud beneath the cloud — running Kubernetes, hosting services, and serving the home from a quiet corner. See the dedicated **Homelab** section below for the full list of rain-borne services.

### 👁️ `imu` — The King of the World

A WSL host. The secret ruler who sits on the Empty Throne. The only one of the pantheon who does not touch bare metal, but instead floats above it — inside the abstraction of Windows, unseen, pulling strings from the shadows.

Imu carries the minimal identity of the user: Nushell, Home Manager, Agents configs. Nothing more. No desktop, no sound, no sun. Just the quiet observation of a hidden supreme ruler.

### 🐉 `loki` — The Accursed Prince

Laptop host: Niri, Helium, Ghostty, the bare dendrite needed to survive on battery and WiFi. He is Nidhogg, enemy of the gods, who will fly out during Ragnarok, the end of the world.

---

## Homelab Services

- **k3s** — the Kubernetes raincloud.
- **Traefik** — the divine gateway; all traffic flows through the Rain God's river.
- **Hermes** — the messenger. Nous Research's agent gateway and dashboard, wired through the homelab to think and speak.
- **SearXNG** — a private, meta-search engine tuned to the user's will.
- **Excalidraw** — the whiteboard of the gods, for sketching ideas in the clouds.
- **Firecrawl** — turn the web into data for the agents.
- **Grafana** — watching the storm from above.
- **LibreSpeed** — measure the rain's velocity.
- **Prometheus** — the all-seeing metrics collector.
- **Wazuh** — security watching the watchers.

---

## Agents

This system is co-piloted by AI agents. Both **OpenCode** and **Pi** are fully wired:

- **AGENTS.md** — the local source of truth for agent behavior and dendritic rules.
- **Skills** — local custom skills plus a **skill-sources** pipeline that imports and keeps up-to-date popular skills from the community.
- **Agents** — sub-agent definitions for specialized tasks, including a **reviewer** and a **simplifier**.
- **Plugins & Commands** — extended toolchains that agents can invoke.

Agents operate with full context of the dendritic layout. They know: *edit the aspect, not the host*. Whether they arrive through OpenCode or Pi, the rule is the same.

---

## Hacking Arsenal

These tools live in the repo as dormant aspects — ready to be grafted onto any host when the red team calls:

- **Recon:** `nmap`, `ffuf`, `feroxbuster`
- **Web:** `burpsuite`
- **Cracking:** `hashcat`, `hydra`, `john`
- **Forensics:** `binwalk`, `exiftool`
- **Network:** `wireshark`, `wireguard-tools`
- **Wordlists:** `rockyou`, guides, and docs mapped to `~/hacking`

Currently disarmed on `nika`, but one uncomment away.

---

## Applications

| Category | Stack |
|---|---|
| **Window manager** | Niri |
| **Editor** | Neovim |
| **Browser** | Helium |
| **Terminal** | Ghostty |
| **Shell** | Nushell + Starship |
| **Navigation** | yazi, zoxide |
| **Version control** | git, jj |
| **Agents** | OpenCode, Pi, Hermes |
| **Security** | doas, SOPS + sops-nix |
| **Env** | direnv + nix-direnv |
| **Obligatory** | fastfetch |
| **Network** | Tailscale, OpenSSH |
| **Desktop tools** | Handy, Nautilus |
| **Communication** | Signal |
| **Gaming/media** | Steam, Sunshine, Spotify |
| **Orchestration** | k3s + Traefik |

---

## Commands

```bash
just update          # update flake inputs
just check           # format, lint, and nix flake check
just build           # dry-run the current host
just switch          # activate the current host
just verify          # check + dry-run
just deploy zaza     # deploy to a remote host over SSH
```

---

*Built with ❄️ and paranoia.*
