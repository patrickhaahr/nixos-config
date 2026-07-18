{ ... }: {
  flake.modules.homeManager.nixfmt = { pkgs, ... }: {
    home.packages = [
      pkgs.nixfmt
      pkgs.nixfmt-tree
    ];
  };
}
