{ self, inputs, ... }:
{
  flake.modules.homeManager.antigravity =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.modules.homeManager.agent-mcp
        self.modules.homeManager.agent-skills
      ];

      programs.antigravity-cli = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli;
        mutableSettings = true;
        mcpServers = lib.mapAttrs (_: server: {
          inherit (server) command args env;
        }) config.agents.mcpServers;
      };

      home = {
        sessionVariables.AGY_CLI_DISABLE_AUTO_UPDATE = "true";
        file = {
          ".gemini/GEMINI.md".source = config.lib.agents.instructions;
          ".gemini/config/skills" = {
            inherit (config.home.file.".agents/skills") source;
            recursive = true;
          };
        };
      };
    };
}
