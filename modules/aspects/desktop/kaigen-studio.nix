{ lib, ... }:
{
  flake.modules.nixos.kaigen-studio =
    { pkgs, ... }:
    let
      version = "1.0.0.013";
      cliVersion = "1.0.0.012";
      cliSha512 = "4e4391d54cf597b97b29561595e59356c5ef68f7b22986b49f89ba1ef2ceca91fc6deb8f795440a06c7b7c5c493eccb83389094992970c3618bd0a9d439919d4";
      studioSha512 = "7fee04b2971ba4f0fd09454ce3de78380e045bf882175b71e3a4c9df58c08e73df69a6a55187bd17710f7b99cd8e08422882ef653db0c8482328d43a468d9011";
      iconSha512 = "7a4316e4d3f785471bfbd338a32d60920843ac86dbae43e2672111aebb3963cc3b56ee5b6d423e7f6ba92d5a37677af3761717c1c799be2aa7076f19aa4b83f3";

      archiveTools = lib.makeBinPath [
        pkgs.gnutar
        pkgs.gzip
        pkgs.xz
      ];

      systemFonts = pkgs.symlinkJoin {
        name = "kaigen-studio-system-fonts";
        paths = with pkgs; [
          inter
          dejavu_fonts
        ];
      };
    in
    {
      environment.systemPackages = [
        (pkgs.stdenvNoCC.mkDerivation {
          pname = "kaigen";
          version = cliVersion;
          src = pkgs.fetchurl {
            url = "https://api.kaigen3d.com/cli/linux/${cliVersion}";
            sha512 = cliSha512;
          };
          dontUnpack = true;
          dontBuild = true;
          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.makeWrapper
          ];
          installPhase = ''
            runHook preInstall
            install -Dm755 "$src" "$out/bin/kaigen"
            runHook postInstall
          '';

          postFixup = ''
            wrapProgram "$out/bin/kaigen" \
              --prefix PATH : "${archiveTools}" \
              --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.openssl ]}"
          '';
          meta = {
            description = "Kaigen engine CLI";
            homepage = "https://kaigen3d.com";
            license = lib.licenses.unfree;
            mainProgram = "kaigen";
            platforms = [ "x86_64-linux" ];
          };
        })
        (pkgs.runCommand "kaigen-studio-${version}"
          {
            binary = pkgs.fetchurl {
              url = "https://api.kaigen3d.com/hub/linux/${version}";
              sha512 = studioSha512;
            };
            icon = pkgs.fetchurl {
              url = "https://api.kaigen3d.com/hub/linux/${version}/icon";
              sha512 = iconSha512;
            };
            nativeBuildInputs = [ pkgs.makeWrapper ];
            meta = {
              description = "Kaigen Studio — create, play and publish Kaigen projects";
              homepage = "https://kaigen3d.com";
              license = lib.licenses.unfree;
              mainProgram = "kaigen-studio";
              platforms = [ "x86_64-linux" ];
            };
          }
          ''
            mkdir -p $out/bin $out/share/kaigen-studio
            install -m755 $binary $out/bin/kaigen-studio
            install -m644 $icon $out/share/kaigen-studio/kaigen-studio.png
            # Same runtime env the helium aspect gives its vendor binary: the
            # Vulkan loader for dlopen, /run/opengl-driver/share for ICDs.
            wrapProgram $out/bin/kaigen-studio \
              --prefix PATH : "${archiveTools}" \
              --prefix LD_LIBRARY_PATH : "${
                lib.makeLibraryPath [
                  pkgs.vulkan-loader
                ]
              }" \
              --prefix XDG_DATA_DIRS : "/run/opengl-driver/share"
            mkdir -p $out/share/applications
            cat > $out/share/applications/kaigen-studio.desktop <<EOF
            [Desktop Entry]
            Type=Application
            Name=Kaigen Studio
            Comment=Create, play and publish Kaigen projects
            Exec=$out/bin/kaigen-studio
            Icon=$out/share/kaigen-studio/kaigen-studio.png
            Terminal=false
            Categories=Development;Graphics;
            StartupWMClass=kaigen-studio
            EOF
          ''
        )
      ];

      systemd.tmpfiles.rules = [
        "d /usr/share 0755 root root -"
        "L+ /usr/share/fonts - - - - ${systemFonts}/share/fonts"
      ];
    };
}
