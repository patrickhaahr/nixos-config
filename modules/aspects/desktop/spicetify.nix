{ inputs, ... }: {
  flake.modules.homeManager.spicetify = { pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      # Snapcraft downloads currently fail here; fetch the current .deb directly
      # from Spotify's apt repository but keep the current nixpkgs packaging.
      spotifyPackage = pkgs.spotify.overrideAttrs (_: {
        version = "1.2.86.502.g8cd7fb22";
        src = pkgs.fetchurl {
          url = "https://repository-origin.spotify.com/pool/non-free/s/spotify-client/spotify-client_1.2.86.502.g8cd7fb22_amd64.deb";
          sha512 = "414373a4094eede6efdb343e3a37e323355a445fd520cb862ef16cc2d5c90d6be0a86b9bc75f3f4842fc807be41ff1074d62c4fae9a92a3d0f44e756c78f54c5";
        };
        nativeBuildInputs = with pkgs; [
          wrapGAppsHook3
          makeShellWrapper
          dpkg
        ];
        unpackPhase = ''
          runHook preUnpack
          dpkg-deb -x "$src" .
          runHook postUnpack
        '';
      });
    in {
    imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

    programs.spicetify = {
      enable = true;
      inherit spotifyPackage;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
    };
  };
}
