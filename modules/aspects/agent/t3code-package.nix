{
  # Shared pin for the desktop and headless service; updates remain declarative.
  flake.modules.nixos.t3code-package = {
    nixpkgs.overlays = [
      (final: prev: {
        t3code = prev.t3code.override {
          t3code-unwrapped = prev.t3code.unwrapped.overrideAttrs (old: rec {
            version = "0.0.46-nightly.20261012.3021";
            src = final.fetchFromGitHub {
              owner = "pingdotgg";
              repo = "t3code";
              tag = "v${version}";
              hash = "sha256-ttvKuVrkknoKICzB/kNTydeI4kjURC78MUJE9bR8tPc=";
            };
            pnpmDeps = old.pnpmDeps.overrideAttrs {
              inherit version src;
              outputHash = "sha256-cIsCMDSm5qwyfNcc5sHPb/sfRxDNyTjVSNyNg4P9+9k=";
            };
          });
        };
      })
    ];
  };
}
