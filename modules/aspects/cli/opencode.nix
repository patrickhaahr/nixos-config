{ inputs, ... }:
let
  agentsSourceDir = ../../../agents;
  configDir = ".agents";
  localSkillsDir = agentsSourceDir + "/skills";
in
{
  flake.modules.homeManager.opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      opencode = pkgs.writeShellApplication {
        name = "opencode";
        text = ''
          export OPENCODE_CONFIG_DIR="${config.home.homeDirectory}/${configDir}"
          exec ${pkgs.opencode}/bin/opencode "$@"
        '';
      };

      externalSkills = import (agentsSourceDir + "/skill-sources") { inherit inputs lib pkgs; };

      localSkillNames = builtins.attrNames (
        lib.filterAttrs (name: type: type == "directory" && !(builtins.hasAttr name externalSkills)) (
          builtins.readDir localSkillsDir
        )
      );

      mergedSkillsDir = pkgs.linkFarm "opencode-skills" (
        builtins.map (name: {
          inherit name;
          path = localSkillsDir + "/${name}";
        }) localSkillNames
        ++ lib.mapAttrsToList (name: path: {
          inherit name;
          inherit path;
        }) externalSkills
      );
    in
    {
      home = {
        packages = [
          pkgs.nodejs
          opencode
        ];
        file = {
          "${configDir}/AGENTS.md".source = agentsSourceDir + "/AGENTS.md";
          "${configDir}/README.md".source = agentsSourceDir + "/README.md";
          "${configDir}/agents".source = agentsSourceDir + "/agents";
          "${configDir}/commands".source = agentsSourceDir + "/commands";
          "${configDir}/plugins".source = agentsSourceDir + "/plugins";
          "${configDir}/skills".source = mergedSkillsDir;
          "${configDir}/opencode.json".text = builtins.toJSON {
            "$schema" = "https://opencode.ai/config.json";
            autoupdate = false;
            instructions = [ "AGENTS*.md" ];
            skills.paths = [ ".skills" ];
            mcp = {
              context7 = {
                type = "remote";
                url = "https://mcp.context7.com/mcp";
                enabled = false;
              };
              shadcn = {
                type = "local";
                command = [
                  "bunx"
                  "shadcn@latest"
                  "mcp"
                ];
                enabled = false;
              };
              astro = {
                type = "remote";
                url = "https://mcp.docs.astro.build/mcp";
                enabled = false;
              };
              learn = {
                type = "remote";
                url = "https://learn.microsoft.com/api/mcp";
                enabled = false;
              };
              burp = {
                type = "remote";
                url = "http://127.0.0.1:9876";
                enabled = false;
              };
              firecrawl = {
                type = "local";
                command = [
                  "${pkgs.coreutils}/bin/env"
                  "FIRECRAWL_API_URL=https://firecrawl.zaza.haahr.me"
                  "npx"
                  "-y"
                  "firecrawl-mcp"
                ];
                enabled = true;
              };
            };
            permission.websearch = "allow";
            provider."llama.cpp" = {
              npm = "@ai-sdk/openai-compatible";
              options = {
                apiKey = "local";
                baseURL = "http://127.0.0.1:8081/v1";
              };
              models = {
                "qwen3-14b".tool_call = true;
                "qwen3.6-35b-a3b".tool_call = true;
              };
            };
          };
        };
      };
    };
}
