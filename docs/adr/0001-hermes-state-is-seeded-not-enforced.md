# Hermes state is seeded, not enforced

Hermes rewrites its own `config.yaml`, skills and memories at run time (dashboard, TUI, `hermes config set`, the curator, `skill_manage`), so Nix seeds that state instead of owning it. Only `services.hermes-agent.settings` (Signal profile routes, the Signal platform, the dashboard) is still merged by the upstream module on every switch.

- `config.nix` writes a key into `config.yaml` only where the file lacks it, so runtime edits survive switches; `hermes config unset <key>` brings the Nix value back on the next switch. Activations that patch `config.yaml` (Signal route chat IDs, enabled plugins) edit the parsed document with ruamel round-trip, never its text, so they hold whatever dialect last wrote the file.
- `seed.nix` copies a skill, script or memory file only where `~/.hermes` lacks it. A fresh host gets the checkpoint back and a live edit survives every switch; refresh the checkpoint by copying the files back into the repo.
- `HERMES_MANAGED=false` is appended after the upstream `home-manager` value (systemd keeps the last assignment) and `.managed` is written as `false`, opting out of managed mode so the CLI, TUI and dashboard may write `config.yaml`. Never run `hermes update`: the package lives in the Nix store.
- The gateway and backend restart on every switch, after the units and the config activations, even when the unit text is unchanged, so a switch cannot leave an old process running against new config.
- Plugins such as talk-desktop are enabled per config file by activation, not through `plugins.enabled`: a managed list would replace the plugins enabled at run time across every profile.
