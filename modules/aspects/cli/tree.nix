_: {
  flake.modules.homeManager.tree = { pkgs, ... }: {
    home.packages = [ pkgs.tree ];
  };
}
