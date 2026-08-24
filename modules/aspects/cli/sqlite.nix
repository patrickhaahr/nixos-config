_: {
  flake.modules.homeManager.sqlite = { pkgs, ... }: {
    home.packages = [ pkgs.sqlite ];
  };
}
