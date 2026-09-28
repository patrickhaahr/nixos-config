{
  flake.modules.homeManager.claude-code =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.claude-code ];

      # Claude Code discovers skills in ~/.claude/skills; the shared skills live
      # in ~/.agents/skills (see agents/SKILL-DIRECTORIES.md), so project it.
      home.file.".claude/skills".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    };
}
