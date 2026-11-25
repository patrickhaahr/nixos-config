{ self, inputs, ... }:
let
  baseSettings = {
    attribution = {
      commit = "";
      pr = "";
    };
    env = {
      DISABLE_TELEMETRY = "1";
      DISABLE_ERROR_REPORTING = "1";
      CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
      CLAUDE_CODE_GB_DISK_CACHE_WHEN_TELEMETRY_OFF = "1";
    };
    disableClaudeAiConnectors = true;
    disableBundledSkills = true;
    autoMemoryEnabled = false;
    permissions.defaultMode = "bypassPermissions";
    skipDangerousModePermissionPrompt = true;
    enabledPlugins = {
      "cc-plugin-plugin-authoring@builtin" = false;
      "cc-plugin-telemetry@builtin" = false;
    };
  };
in
{
  flake.modules.homeManager.claude-code =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      managedSettings = pkgs.writeText "claude-managed-settings.json" (
        builtins.toJSON (
          lib.recursiveUpdate baseSettings {
            extraKnownMarketplaces.cursor-plugins.source = {
              source = "github";
              repo = "cursor/plugins";
            };
            enabledPlugins."pstack@cursor-plugins" = true;
            pluginConfigs."cc-plugin-agents-md@builtin".options.instructionFiles = "claude-md-or-agents-md";
          }
        )
      );
      managedState = pkgs.writeText "claude-managed-state.json" (
        builtins.toJSON {
          mcpServers = lib.mapAttrs (_: server: {
            type = "stdio";
            inherit (server) command args env;
          }) config.agents.mcpServers;
        }
      );
      mergeJson = lib.getExe config.lib.agents.mergeJson;
      homeDir = config.home.homeDirectory;
    in
    {
      key = "claude-code";

      imports = [
        self.modules.homeManager.agent-mcp
        self.modules.homeManager.agent-skills
      ];

      lib.agents.claude.settings = managedSettings;

      home = {
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code ];

        file = {
          ".claude/CLAUDE.md".source = config.lib.agents.instructions;

          ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/.agents/skills";
        };

        activation.claudeManagedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${mergeJson} ${homeDir}/.claude/settings.json ${managedSettings}
          run ${mergeJson} ${homeDir}/.claude.json ${managedState}
        '';
      };
    };

  flake.modules.homeManager.claude-specialists =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      settingsFormat = pkgs.formats.json { };
      claude = lib.getExe inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
      specialists = lib.filterAttrs (
        _: specialist: lib.elem "claude" specialist.harnesses
      ) config.agents.specialists;

      settings = settingsFormat.generate "claude-specialist-settings.json" baseSettings;

      plugin =
        name: content:
        pkgs.linkFarm "claude-${name}-plugin" (
          {
            ".claude-plugin/plugin.json" = settingsFormat.generate "plugin.json" {
              inherit name;
              version = "1.0.0";
            };
            "hooks/hooks.json" = settingsFormat.generate "hooks.json" {
              hooks.SessionStart = [
                {
                  hooks = [
                    {
                      type = "command";
                      command = "${pkgs.coreutils}/bin/cat ${content.instructions}";
                    }
                  ];
                }
              ];
            };
          }
          // lib.optionalAttrs (content.skills != null) { inherit (content) skills; }
        );

      command =
        name: specialist:
        let
          content = config.lib.agents.specialists.${name};
          mcpConfig = settingsFormat.generate "claude-${name}-mcp.json" {
            mcpServers = lib.mapAttrs (
              _: server: lib.optionalAttrs (server ? url) { type = "http"; } // server
            ) specialist.mcpServers;
          };
        in
        pkgs.writeShellApplication {
          name = "claude-${name}";
          runtimeEnv = specialist.env;
          runtimeInputs = specialist.packages ++ [
            pkgs.coreutils
            pkgs.jq
          ];
          text = ''
            if [[ ''${1-} != -* && $# -gt 0 ]]; then exec ${claude} "$@"; fi
            settings=$(< ${settings})
            args=()
            while (( $# )); do
              if [[ $1 == --settings ]]; then
                caller=$2
                if [[ -f $caller ]]; then caller=$(< "$caller"); fi
                settings=$(jq -cs '.[0] * .[1]' <<<"$settings $caller")
                shift 2
              else
                args+=("$1")
                shift
              fi
            done
            exec ${claude} \
              --settings "$settings" \
              --strict-mcp-config --mcp-config=${mcpConfig} \
              --plugin-dir=${plugin name content} \
              "''${args[@]}" --setting-sources=
          '';
        };
    in
    {
      key = "claude-specialists";

      imports = [
        self.modules.homeManager.agent-skills
        self.modules.homeManager.t3code-settings
      ];

      config = {
        home.packages = lib.mapAttrsToList command specialists;

        t3code.providerInstances = lib.mapAttrs' (
          name: specialist:
          lib.nameValuePair "claude-${name}" {
            driver = "claudeAgent";
            displayName = "Claude ${specialist.displayName}";
            enabled = true;
            config.binaryPath = "claude-${name}";
          }
        ) specialists;
      };
    };
}
