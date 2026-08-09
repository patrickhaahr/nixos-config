_: {
  flake.modules.homeManager.yazi = { pkgs, ... }: {
    home.packages = [ pkgs.yazi ];
  };
}
