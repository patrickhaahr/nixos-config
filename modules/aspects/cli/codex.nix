let
  agentsSourceDir = ../../../agents;
in
{
  flake.modules.homeManager.codex = { pkgs, ... }: {
    home.packages = [ pkgs.codex ];
    # Codex only reads ~/.codex/AGENTS.md, never ~/.agents/AGENTS.md
    home.file.".codex/AGENTS.md".source = agentsSourceDir + "/AGENTS.md";
  };
}
