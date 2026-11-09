{ self, inputs, ... }:
let
  agentsSourceDir = ../../../agents;
in
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
      imports = [ self.modules.homeManager.agent-mcp ];

      home = {
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi ];

        file = {
          ".pi/agent/settings.json".source = settingsFormat.generate "pi-settings.json" {
            defaultProvider = "github-copilot";
            defaultModel = "gpt-5.6-sol";
            npmCommand = [ "${pkgs.nodejs_22}/bin/npm" ];

            packages = [
              "npm:@dietrichgebert/ponytail@4.9.0"
              "npm:@ff-labs/pi-fff@0.10.3"
              "npm:pi-web-access@0.23.0"
              "npm:pi-mcp-adapter@2.26.0"
              "npm:pi-subagents@0.50.0"
            ];
          };

          ".pi/agent/AGENTS.md".source = agentsSourceDir + "/AGENTS.md";
          ".pi/agent/agents".source = agentsSourceDir + "/agents";
          ".pi/agent/prompts".source = agentsSourceDir + "/commands";

          ".pi/web-search.json".source = settingsFormat.generate "pi-web-search.json" {
            provider = "firecrawl";
            firecrawlBaseUrl = "https://firecrawl.zaza.haahr.me";
            firecrawlApiVersion = "v2";
            firecrawlFreshScrape = true;
            ssrf.allowRanges = [ "100.120.202.71/32" ];
          };
        };

        activation.piManagedMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe config.lib.agents.mergeJson} ${config.home.homeDirectory}/.pi/agent/mcp.json ${managedMcp}
        '';
      };
    };
}
