{ ... }: {
  flake.modules.homeManager.pi = { pkgs, ... }: {
    home.packages = [ pkgs.pi-coding-agent ];
  };
}
