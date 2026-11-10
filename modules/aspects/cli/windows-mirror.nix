_:
let
  agentsSourceDir = ../../../agents;
in
{
  flake.modules.homeManager.windows-mirror =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.agents.windows) home;
      inherit (config.lib.agents) claude codex;
      instructions = agentsSourceDir + "/AGENTS.md";
      skills = config.home.file.".agents/skills".source;
      rsync = "${lib.getExe pkgs.rsync} -rLt --delete --chmod=u+w";
    in
    {
      options.agents.windows.home = lib.mkOption {
        type = lib.types.str;
        example = "/mnt/c/Users/me";
        description = "WSL path of the Windows profile that receives the agent instructions, skills and settings.";
      };

      # Windows cannot follow WSL symlinks into /nix/store, so the profile gets real copies.
      config.home.activation.windowsMirror = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [[ -d ${home} ]]; then
          run mkdir -p ${home}/.claude/skills ${home}/.codex ${home}/.agents/skills
          run install -m 644 ${instructions} ${home}/.claude/CLAUDE.md
          run install -m 644 ${instructions} ${home}/.codex/AGENTS.md
          # synced/ and .trash/ belong to Claude Code itself.
          run ${rsync} --filter='P synced/' --filter='P .trash/' ${skills}/ ${home}/.claude/skills/
          # Codex reads user skills from ~/.agents/skills.
          run ${rsync} ${skills}/ ${home}/.agents/skills/
          run ${lib.getExe config.lib.agents.mergeJson} ${home}/.claude/settings.json ${claude.settings}
          run ${codex.mergeToml} ${home}/.codex/config.toml ${codex.portableSettings}
        else
          warnEcho "Windows profile ${home} not found; skipping the Windows mirror"
        fi
      '';
    };
}
