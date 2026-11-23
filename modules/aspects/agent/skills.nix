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
      sources = import (contentDir + "/skill-sources") {
        inherit inputs lib pkgs;
      };

      externalSkills = removeAttrs sources.skills config.agents.skills.exclude;

      localSkillNames = builtins.attrNames (
        lib.filterAttrs (name: type: type == "directory" && !(builtins.hasAttr name externalSkills)) (
          builtins.readDir localSkillsDir
        )
      );

      skillPaths = lib.genAttrs localSkillNames (name: localSkillsDir + "/${name}") // externalSkills;

      mergedSkillsDir = pkgs.runCommand "agent-skills" { } ''
        mkdir $out
        ${lib.concatStrings (
          lib.mapAttrsToList (name: path: ''
            cp -rL --no-preserve=mode ${path} $out/${lib.escapeShellArg name}
          '') skillPaths
        )}
        for skill in $out/*/; do
          grep -q '^disable-model-invocation: true' "$skill/SKILL.md" || continue
          policy="$skill/agents/openai.yaml"
          grep -q '^policy:' "$policy" 2>/dev/null && continue
          mkdir -p "$skill/agents"
          [[ ! -s $policy || -z $(tail -c1 "$policy") ]] || echo >> "$policy"
          printf 'policy:\n  allow_implicit_invocation: false\n' >> "$policy"
        done
      '';
    in
    {
      key = "agent-skills";

      options.agents = {
        skills.exclude = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "External skills left out of this user's shared skill directory.";
        };
        extraInstructions = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Sections appended to `agents/AGENTS.md` for every harness of this user.";
        };
      };

      config = {
        lib.agents = {
          instructions = pkgs.writeText "AGENTS.md" (
            lib.concatStringsSep "\n" (
              [ (builtins.readFile (contentDir + "/AGENTS.md")) ]
              ++ lib.optional (config.agents.extraInstructions != "") config.agents.extraInstructions
            )
          );
          specialists = lib.mapAttrs' (
            file: _:
            let
              name = lib.removeSuffix ".md" file;
            in
            lib.nameValuePair name {
              skills = sources.bundles.${name} or null;
              instructions = contentDir + "/specialists/${file}";
            }
          ) (builtins.readDir (contentDir + "/specialists"));
        };

        home.file = {
          ".agents/AGENTS.md".source = config.lib.agents.instructions;
          ".agents/skills".source = mergedSkillsDir;
        };
      };
    };
}
