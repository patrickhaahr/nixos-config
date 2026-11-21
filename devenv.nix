{ pkgs, ... }:

{
  packages = with pkgs; [
    ast-grep
    jq
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
