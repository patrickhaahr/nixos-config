{ inputs, ... }:
let
  agentsSourceDir = ../../../agents;
in
{
  flake.modules.homeManager.codex = { pkgs, ... }: {
    home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex ];
    # Codex only reads ~/.codex/AGENTS.md, never ~/.agents/AGENTS.md
    home.file.".codex/AGENTS.md".source = agentsSourceDir + "/AGENTS.md";
  };
}
