{ self, inputs, ... }:
let
  agentsSourceDir = ../../../agents;
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
        builtins.toJSON {
          attribution = {
            commit = "";
            pr = "";
          };
          env = {
            CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-5-5";
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
            CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
          };
          permissions.defaultMode = "bypassPermissions";
          skipDangerousModePermissionPrompt = true;
          enabledPlugins."cc-plugin-plugin-authoring@builtin" = false;
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
      imports = [ self.modules.homeManager.agent-mcp ];

      # Unlike managedState, these settings carry no Linux store paths, so other platforms can reuse them.
      lib.agents.claude.settings = managedSettings;

      home = {
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code ];

        file = {
          ".claude/CLAUDE.md".source = agentsSourceDir + "/AGENTS.md";

          ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/.agents/skills";
        };

        activation.claudeManagedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${mergeJson} ${homeDir}/.claude/settings.json ${managedSettings}
          run ${mergeJson} ${homeDir}/.claude.json ${managedState}
        '';
      };
    };
}
