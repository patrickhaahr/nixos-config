{ self, ... }:
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
      inherit (config.lib.agents) claude codex t3code;
      inherit (config.lib.agents) instructions;
      skills = config.home.file.".agents/skills".source;
      rsync = "${lib.getExe pkgs.rsync} -rLt --delete --chmod=u+w";

      git = config.programs.git;
      inherit (config.lib.git) guardrailHooks;

      gitConfig = pkgs.writeText "gitconfig" (
        lib.generators.toGitINI (
          lib.getAttrs [ "user" "url" "init" "pull" "rebase" "alias" ] git.settings
          // {
            core = {
              inherit (git.settings.core) editor;

              symlinks = true;
            };
            hook = builtins.mapAttrs (name: hook: {
              inherit (hook) event;
              command = toString ([ "bash ~/.config/git/hooks/${name}" ] ++ hook.args);
            }) guardrailHooks;
          }
        )
        + lib.generators.toGitINI {
          includeIf = lib.listToAttrs (
            map (
              include:

              lib.nameValuePair (lib.replaceStrings [ "gitdir:/mnt/c/" ] [ "gitdir:C:/" ] include.condition) {
                inherit (include) path;
              }
            ) git.includes
          );
        }
      );
    in
    {
      imports = [
        self.modules.homeManager.agent-skills
        self.modules.homeManager.claude-code
        self.modules.homeManager.codex
        self.modules.homeManager.t3code-environment
      ];

      options.agents.windows.home = lib.mkOption {
        type = lib.types.str;
        example = "/mnt/c/Users/me";
        description = "WSL path of the Windows profile that receives the agent instructions, skills and settings.";
      };

      config.programs.git.includes = [
        {
          condition = "gitdir:/mnt/c/Projekter/";
          path = "~/.config/git/config-work";
        }
      ];

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

          # ~/.gitconfig, not ~/.config/git/config, because git reads it last and it would win.
          run mkdir -p ${home}/.config/git/hooks
          run install -m 644 ${gitConfig} ${home}/.gitconfig
          run install -m 644 ${config.xdg.configFile."git/ignore".source} ${home}/.config/git/ignore
          run install -m 644 ${
            config.xdg.configFile."git/config-work".source
          } ${home}/.config/git/config-work
          ${lib.concatMapAttrsStringSep "\n" (
            name: hook: "run install -m 644 ${pkgs.writeText name hook.text} ${home}/.config/git/hooks/${name}"
          ) guardrailHooks}
          ${lib.concatMapAttrsStringSep "\n" (name: value: ''
            run --quiet /mnt/c/Windows/System32/setx.exe ${name} ${lib.escapeShellArg value} \
              || warnEcho "Could not set ${name} in the Windows user environment"
          '') t3code.environment}
        else
          warnEcho "Windows profile ${home} not found; skipping the Windows mirror"
        fi
      '';
    };
}
