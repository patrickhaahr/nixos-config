# Hermes profiles and secrets

Hermes gateway secrets live in sops-rendered files (the gateway env in `$HERMES_HOME/.env`, the OpenHome key in its own file), never in plaintext in the repo or the Nix store; `config.yaml` references them as `${VAR}`, which Hermes expands at load time.

- Named profiles load their own `config.yaml` and `.env`, not the shared ones. A setting made through Home Manager reaches only the shared profile, so activation enables plugins in every profile's `config.yaml` and copies the sops OpenHome API key into the `.env` of each profile whose config references it; without the copy, `${OPENHOME_API_KEY}` in a profile's MCP header expands empty and the call fails with 401.
- `profile_routes` are read literally, with no `${VAR}` expansion, so the repo holds placeholders and activation substitutes the Signal group and user IDs from the sops `.env` after the upstream config merge. The DM route's user is the one allowed user who is not the home channel, and stays unresolved unless exactly one such user exists.
- A Signal DM's `chat_id` is the sender's ID, so a DM route scopes to that user's DMs while their group messages keep the group's profile.
- Only the shared default profile owns the Signal adapter; named profiles are targets of routes, so activation strips `SIGNAL_HTTP_URL` and `SIGNAL_ACCOUNT` from every named profile's `.env`. The gateway reads every profile's `.env` at boot, and a profile pointing at an account signal-cli lacks fails its contact refresh and home-channel notice.
- `skills.external_dirs` is seeded empty so the default profile carries only its local orchestration skills; specialist profiles own domain skills.
- Unauthorized Signal DMs are dropped silently: no pairing codes or decline messages go to unknown users.
