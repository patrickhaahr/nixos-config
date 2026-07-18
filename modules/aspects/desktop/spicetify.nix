{ inputs, ... }: {
  flake.modules.homeManager.spicetify =
    { lib, pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      spotifyPackage = pkgs.spotify.overrideAttrs (_: {
        postFixup = ''
          wrapProgram "$out/bin/spotify" --add-flags "--password-store=basic"
        '';
      });
    in
    {
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
