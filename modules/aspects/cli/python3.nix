_: {
  flake.modules.homeManager.python3 = { pkgs, ... }: {
    home.packages = [ pkgs.python3 ];
  };
}
