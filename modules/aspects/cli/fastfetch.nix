_: {
  flake.modules.homeManager.fastfetch = { pkgs, ... }: {
    home.packages = [ pkgs.fastfetch ];
  };
}
