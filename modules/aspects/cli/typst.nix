{ ... }: {
  flake.modules.homeManager.typst = { pkgs, ... }: {
    home.packages = [ pkgs.typst ];
  };
}
