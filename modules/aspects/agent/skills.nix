{ inputs, ... }:
let
  contentDir = ../../../agents;
  localSkillsDir = contentDir + "/skills";
in
{
  flake.modules.homeManager.agent-skills =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      externalSkills = removeAttrs (import (contentDir + "/skill-sources") {
        inherit inputs lib pkgs;
      }) config.agents.skills.exclude;

      localSkillNames = builtins.attrNames (
        lib.filterAttrs (name: type: type == "directory" && !(builtins.hasAttr name externalSkills)) (
          builtins.readDir localSkillsDir
        )
      );

      mergedSkillsDir = pkgs.linkFarm "agent-skills" (
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
      key = "agent-skills";

      options.agents.skills.exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "External skills left out of this user's shared skill directory.";
      };

      config = {
        lib.agents.instructions = contentDir + "/AGENTS.md";

        home.file = {
          ".agents/AGENTS.md".source = config.lib.agents.instructions;
          ".agents/skills".source = mergedSkillsDir;
        };
      };
    };
}
