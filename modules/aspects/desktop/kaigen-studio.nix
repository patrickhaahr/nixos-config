# Kaigen Studio and CLI. Version and sha512 pins come from the vendor's
# https://api.kaigen3d.com/studio.sh and install.sh scripts respectively.
#
# To bump a release: re-read https://api.kaigen3d.com/studio.sh and update
# Studio version + both sha512 values; use install.sh for the CLI pin.
{ lib, ... }:
{
  flake.modules.nixos.kaigen-studio =
    { pkgs, ... }:
    let
      version = "1.0.0.010";
      cliVersion = "1.0.0.010";
      cliSha512 = "90b9d81a41e904e74d8ff72b3fa85d5dadfed45f04e00e5b4d4c80cac375ebba4bb41bae76b6a66bfe4bd11182dce503c7c496c22c4ef6c3d0edf76f4a7c1727";
      studioSha512 = "cc9ae336bfe7aa7c989f3a8f894bdea25eaa32471a20255c1bd81f80fe1d7409548f21f76717525a9b397c43a6e754ec9f3af01e0f2fa2e7ba6b5a21afb782fd";
      iconSha512 = "7a4316e4d3f785471bfbd338a32d60920843ac86dbae43e2672111aebb3963cc3b56ee5b6d423e7f6ba92d5a37677af3761717c1c799be2aa7076f19aa4b83f3";
      # Toolchain installation shells out to tar; supply its decompressors too
      # so desktop launches do not depend on the user's shell environment.
      archiveTools = lib.makeBinPath [
        pkgs.gnutar
        pkgs.gzip
        pkgs.xz
      ];
      # The engine scans /usr/share/fonts, /usr/local/share/fonts and ~/.fonts
      # for system fonts; NixOS has none of those, so this tmpfiles rule exposes
      # the fonts we ship to one of them.
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
          # HTTPS support is loaded with dlopen, so ELF dependency scanning
          # cannot discover OpenSSL automatically.
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
