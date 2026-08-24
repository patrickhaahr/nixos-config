_: {
  flake.modules.homeManager.unzip = { pkgs, ... }: {
    home.packages = [ pkgs.unzip ];
  };
}
