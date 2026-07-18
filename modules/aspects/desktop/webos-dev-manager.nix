{
  flake.modules.nixos.webos-dev-manager =
    { lib, pkgs, ... }:
    let
      basePackage = pkgs.appimageTools.wrapType2 {
        pname = "webos-dev-manager";
        version = "1.99.16";
        src = pkgs.fetchurl {
          url = "https://github.com/webosbrew/dev-manager-desktop/releases/download/v1.99.16/webos-dev-manager_1.99.16_amd64.AppImage";
          hash = "sha256-1Eg8flL81vJXcGG9492tePqI4LpvEap2spuYtfIwAKU=";
        };
        extraPkgs =
          appPkgs: with appPkgs; [
            fontconfig
            freetype
            harfbuzz
            libdrm
            libGL
            libx11
            libxcb
            libxkbcommon
            mesa
            stdenv.cc.cc.lib
            webkitgtk_4_1
            zlib
          ];
      };
      package = pkgs.symlinkJoin {
        name = "webos-dev-manager-1.99.16";
        paths = [ basePackage ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/webos-dev-manager" \
            --set WEBKIT_DISABLE_DMABUF_RENDERER 1
        '';
      };
    in
    {
      environment.systemPackages = [
        (pkgs.symlinkJoin {
          name = "webos-dev-manager";
          paths = [ package ];
          postBuild = ''
            mkdir -p "$out/share/applications"
            cp ${
              pkgs.makeDesktopItem {
                name = "webos-dev-manager";
                desktopName = "webOS Dev Manager";
                comment = "Device and Dev Mode Manager for webOS TV";
                exec = lib.getExe' package "webos-dev-manager";
                categories = [ "Development" ];
                terminal = false;
              }
            }/share/applications/webos-dev-manager.desktop "$out/share/applications/"
          '';
        })
      ];
    };
}
