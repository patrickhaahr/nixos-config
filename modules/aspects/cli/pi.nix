let
  agentsSourceDir = ../../../agents;
in
_: {
  flake.modules.homeManager.pi =
    { pkgs, ... }:
    let
      settingsFormat = pkgs.formats.json { };
    in
    {
      home = {
        packages = [ pkgs.pi-coding-agent ];

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

          ".pi/agent/agents".source = agentsSourceDir + "/agents";
          ".pi/agent/prompts".source = agentsSourceDir + "/commands";
          ".pi/agent/extensions/global-skills.ts".source = agentsSourceDir + "/extensions/global-skills.ts";

          ".pi/web-search.json".source = settingsFormat.generate "pi-web-search.json" {
            provider = "firecrawl";
            firecrawlBaseUrl = "https://firecrawl.zaza.haahr.me";
            firecrawlApiVersion = "v2";
            firecrawlFreshScrape = true;
            ssrf.allowRanges = [ "100.120.202.71/32" ];
          };
        };
      };
    };
}
