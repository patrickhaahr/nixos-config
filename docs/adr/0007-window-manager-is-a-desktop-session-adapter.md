# The window manager is an adapter behind the desktop session

Each app aspect declares its keybinds, startup commands and window rules as WM-neutral `desktop.*` options, and the window manager aspect (niri today) is the only module that translates them into its own config and sets the greetd session command. That way, switching window managers replaces one adapter while every app keeps its binds. It also replaces the niri aspect probing other aspects' options with `hasAttr`.

- A key chord made only of modifiers (`Ctrl+Alt`) is one entry in the session. The niri adapter expands it into every modifier order (ADR-0005).
- Startup entries that name a workspace start there in the background: the niri adapter focuses that workspace, starts them, and returns to workspace 1, because window rules alone did not keep Spotify off workspace 1.
- Layout binds (columns, monitors, workspaces) stay WM-native in the adapter. A second adapter should bind the same keys. A neutral layout vocabulary is deferred until a second window manager exists.
- Monitor layout is host hardware and lives in the host's hardware aspect as `desktop.outputs`.
- Workspace names (`"1"` home, `"2"` background) and `windowRules.atStartup` are still niri-shaped, and app aspects use them directly. A second adapter must declare the same named workspaces.
- Apps that every desktop user gets (ghostty, noctalia) have their NixOS aspects imported by the identity aspects next to their Home Manager halves. The identity aspects also set the greetd user. A host that installs an app but shouldn't start it at login sets an app option, such as `programs.signal.autostart = false` on the laptops, instead of a host-wide profile flag.
