{ pkgs, ... }:

{
  packages = with pkgs; [
    just
    nixfmt
    nixfmt-tree
    statix
  ];

  git-hooks.hooks = {
    nixfmt-rfc-style.enable = true;
    statix.enable = true;
  };
}
