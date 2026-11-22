{ self, inputs, ... }: {
  flake.modules.nixos.spicetify =
    { lib, pkgs, ... }:
    let
      playerctl = lib.getExe pkgs.playerctl;
      spotifyAutoplay = pkgs.writeShellScriptBin "spotify-autoplay" ''
        spotify &

        for _ in $(seq 1 60); do
          if ${playerctl} -p spotify status >/dev/null 2>&1; then
            ${playerctl} -p spotify volume 1.0
            exec ${playerctl} -p spotify play
          fi

          sleep 1
        done
      '';
    in
    {
      imports = [ self.modules.nixos.desktop-session ];
      home-manager.sharedModules = [ self.modules.homeManager.spicetify ];

      desktop = {
        startup = [
          {
            command = [ (lib.getExe spotifyAutoplay) ];
            workspace = "2";
          }
        ];
        windowRules = [
          {
            appId = "^Spotify$";
            atStartup = true;
            workspace = "2";
            focus = false;
          }
        ];
      };
    };

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
