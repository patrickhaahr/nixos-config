{ pkgs, ... }:

{
  packages = with pkgs; [
    just
    nixfmt
    nixfmt-tree
    statix
  ];

  git-hooks.hooks = {
    nixfmt.enable = true;
    statix.enable = true;
  };
}
