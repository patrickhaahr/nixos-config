{ inputs, ... }:
{
  flake.modules.homeManager.claude-code =
    { config, pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.system}.claude-code ];

      # Claude Code discovers skills in ~/.claude/skills; the shared skills live
      # in ~/.agents/skills (see agents/SKILL-DIRECTORIES.md), so project it.
      home.file.".claude/skills".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    };
}
