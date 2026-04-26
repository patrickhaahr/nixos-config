{ ... }: {
  flake.modules.homeManager.cursor = { pkgs, ... }: {
    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.stdenvNoCC.mkDerivation {
        pname = "bibata-modern-classic";
        version = "local";
        src = ../../../cursor/Bibata-Modern-Classic;

        installPhase = ''
          mkdir -p "$out/share/icons/Bibata-Modern-Classic"
          cp -r . "$out/share/icons/Bibata-Modern-Classic"
        '';
      };
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
