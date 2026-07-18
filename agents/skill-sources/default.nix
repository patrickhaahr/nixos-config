{ inputs, lib, pkgs }:
let
  providers = [
    (import ./agent-browser.nix { inherit inputs; })
    (import ./anthropic.nix { inherit inputs; })
    (import ./dmmulroy.nix { inherit inputs pkgs; })
    (import ./dotnet-skillz.nix { inherit inputs; })
    (import ./frontend-slides.nix { inherit inputs; })
    (import ./mattpocock.nix { inherit inputs; })
    (import ./rhys-sullivan.nix { inherit inputs; })
    (import ./sentry.nix { inherit inputs; })
    (import ./typst.nix { inherit inputs; })
    (import ./vercel.nix { inherit inputs; })
    (import ./wshobson.nix { inherit inputs; })
  ];
in
lib.foldl' lib.mergeAttrs { } providers
