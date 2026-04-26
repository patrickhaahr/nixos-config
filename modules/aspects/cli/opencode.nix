{ ... }:
let
  opencodeSourceDir = ../../../agent;
in {
  flake.modules.homeManager.opencode = {
    home.file.".config/opencode/AGENTS.md".source = opencodeSourceDir + "/AGENTS.md";
    home.file.".config/opencode/README.md".source = opencodeSourceDir + "/README.md";
    home.file.".config/opencode/agents".source = opencodeSourceDir + "/agents";
    home.file.".config/opencode/commands".source = opencodeSourceDir + "/commands";
    home.file.".config/opencode/plugins".source = opencodeSourceDir + "/plugins";
    home.file.".config/opencode/skills".source = opencodeSourceDir + "/skills";
    home.file.".config/opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      autoupdate = false;
      instructions = [ "AGENTS*.md" ];
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          enabled = true;
        };
        shadcn = {
          type = "local";
          command = [ "bunx" "shadcn@latest" "mcp" ];
          enabled = false;
        };
        astro = {
          type = "remote";
          url = "https://mcp.docs.astro.build/mcp";
          enabled = false;
        };
      };
    };
  };
}
