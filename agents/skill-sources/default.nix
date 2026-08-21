{
  inputs,
  lib,
  pkgs,
}:
let
  providers = [
    (import ./agent-browser.nix { inherit inputs; })
    (import ./anthropic.nix { inherit inputs; })
    (import ./better-auth.nix { inherit inputs; })
    (import ./cursor.nix { inherit inputs; })
    (import ./diagram-design.nix { inherit inputs; })
    (import ./dmmulroy.nix { inherit inputs pkgs; })
    (import ./dotnet-skillz.nix { inherit inputs; })
    (import ./frontend-slides.nix { inherit inputs; })
    (import ./jakubkrehel.nix { inherit inputs; })
    (import ./kitlangton.nix { inherit inputs; })
    (import ./mattpocock.nix { inherit inputs; })
    (import ./marketing.nix { inherit inputs; })
    (import ./rhys-sullivan.nix { inherit inputs; })
    (import ./sentry.nix { inherit inputs; })
    (import ./typst.nix { inherit inputs; })
    (import ./vercel.nix { inherit inputs; })
  ];
in
lib.foldl' lib.mergeAttrs { } providers
