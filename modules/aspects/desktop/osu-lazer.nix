{
  flake.modules.homeManager.osu-lazer = { pkgs, ... }: {
    home.packages = [
      (pkgs.appimageTools.wrapType2 {
        pname = "osu-tachyon";
        version = "2026.918.0";
        extraPkgs = _: [ pkgs.icu ];
        src = pkgs.fetchurl {
          url = "https://github.com/ppy/osu/releases/download/2026.918.0-tachyon/osu.AppImage";
          hash = "sha256-4wwtNWDqghwuJyvKz8pXuy0UfKAlwamV7UW82im6CFQ=";
        };
        meta = {
          description = "osu!lazer tachyon (cutting-edge) stream";
          homepage = "https://github.com/ppy/osu";
          license = pkgs.lib.licenses.unfreeRedistributable;
          mainProgram = "osu-tachyon";
          platforms = [ "x86_64-linux" ];
        };
        postInstall = ''
          mv $out/bin/osu.AppImage $out/bin/osu-tachyon
        '';
      })
    ];
  };
}
