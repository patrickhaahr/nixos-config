{ self, inputs, ... }:
{
  flake.modules.homeManager.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      settingsFormat = pkgs.formats.json { };
      managedMcp = settingsFormat.generate "pi-managed-mcp.json" {
        mcpServers = lib.mapAttrs (_: server: {
          inherit (server) command args env;
        }) config.agents.mcpServers;
      };
    in
    {
      imports = [
        self.modules.homeManager.agent-mcp
        self.modules.homeManager.agent-skills
      ];

      home = {
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi ];

        file = {
          ".pi/agent/settings.json".source = settingsFormat.generate "pi-settings.json" {
            defaultProvider = "claude-code";
            defaultModel = "claude-opus-5-5";
            npmCommand = [ "${pkgs.nodejs_22}/bin/npm" ];

            packages = [
              "npm:@ff-labs/pi-fff@0.10.3"
              "${inputs.pi-claude-code}"
            ];
          };

          ".pi/agent/AGENTS.md".source = config.lib.agents.instructions;
        };

        activation.piManagedMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe config.lib.agents.mergeJson} ${config.home.homeDirectory}/.pi/agent/mcp.json ${managedMcp}
        '';
      };
    };
}
