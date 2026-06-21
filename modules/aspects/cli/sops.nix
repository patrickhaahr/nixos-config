{ ... }: {
  flake.modules.homeManager.sops = { pkgs, ... }: {
    home.packages = [ pkgs.sops ];
  };
}
