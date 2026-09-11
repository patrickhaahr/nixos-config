{ pkgs, ... }:

{
  packages = with pkgs; [
    just
    nixfmt
    nixfmt-tree
    statix
  ];
}
