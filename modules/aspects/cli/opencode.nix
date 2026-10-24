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
      opencodePackage = inputs.llm-agents.packages.${pkgs.system}.opencode2;

      opencode = pkgs.writeShellApplication {
        name = "opencode";
        text = ''
          export OPENCODE_CONFIG_DIR="${config.home.homeDirectory}/${configDir}"
          exec ${opencodePackage}/bin/opencode2 "$@"
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
          pkgs.uv
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
            "$schema" = "https://opencode.ai/v2/config.json";
            update = "disable";
            instructions = [ "AGENTS*.md" ];
            skills = [ ".skills" ];
            permissions = [
              {
                action = "websearch";
                resource = "*";
                effect = "allow";
              }
            ];
            mcp.servers.executor = {
              type = "remote";
              url = "https://executor.zaza.haahr.me/mcp";
            };
          };
        };
      };
    };
}
