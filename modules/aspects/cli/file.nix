_: {
  flake.modules.homeManager.file = { pkgs, ... }: {
    home.packages = [ pkgs.file ];
  };
}
