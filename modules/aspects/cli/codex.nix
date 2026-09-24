_: {
  flake.modules.homeManager.codex = { pkgs, ... }: {
    home.packages = [ pkgs.codex ];
  };
}
