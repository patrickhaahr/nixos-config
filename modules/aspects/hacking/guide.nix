{ ... }: {
  flake.modules.homeManager."hacking-guide" = {
    home.file."hacking/AGENTS.md".source = ./AGENTS.md;
  };
}
