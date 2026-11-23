{ self, inputs, ... }:
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
        builtins.toJSON {
          attribution = {
            commit = "";
            pr = "";
          };
          env = {
            DISABLE_TELEMETRY = "1";
            DISABLE_ERROR_REPORTING = "1";
            CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
            CLAUDE_CODE_GB_DISK_CACHE_WHEN_TELEMETRY_OFF = "1";
            CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-5-5";
          };
          disableClaudeAiConnectors = true;
          permissions.defaultMode = "bypassPermissions";
          skipDangerousModePermissionPrompt = true;
          extraKnownMarketplaces.cursor-plugins.source = {
            source = "github";
            repo = "cursor/plugins";
          };
          enabledPlugins = {
            "cc-plugin-plugin-authoring@builtin" = false;
            "cc-plugin-privacy@builtin" = false;
            "cc-plugin-telemetry@builtin" = false;
            "cloudflare@synced" = false;
            "mattpocock-skills@synced" = false;
            "pstack@cursor-plugins" = true;
          };
          pluginConfigs."cc-plugin-agents-md@builtin".options.instructionFiles = "claude-md-or-agents-md";
        }
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
}
