{ inputs, lib }:
let
  providers = [
    (import ./agent-browser.nix { inherit inputs; })
    (import ./anthropic.nix { inherit inputs; })
    (import ./frontend-slides.nix { inherit inputs; })
    (import ./mattpocock.nix { inherit inputs; })
    (import ./sentry.nix { inherit inputs; })
    (import ./vercel.nix { inherit inputs; })
  ];
in
lib.foldl' lib.mergeAttrs { } providers
