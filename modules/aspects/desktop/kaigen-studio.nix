{ lib, self, ... }:
{
  flake.modules.nixos.kaigen-studio =
    { pkgs, ... }:
    let
      version = "1.0.0.015";
      cliVersion = "1.0.0.014";
      cliSha512 = "8e3e29ce688c48cf2d64e5d835cc3a1e06fb21febcdc22dd1239b5c2df5f869523054c5140c491b60cf71fcbe93c4bec432a2078dd6e667ceb8ea518db69b0e1";
      studioSha512 = "f505aa93b82f20c9f11abf06e0802f24d6ea64ee222f5c2b1d41a34a43da11e3dc968ae6713550ae2703ebee9c0debaab2729d9aa67d63887cc59152434c4525";
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

      home-manager.sharedModules = [ self.modules.homeManager.kaigen-studio ];
    };

  flake.modules.homeManager.kaigen-studio = {
    imports = [ self.modules.homeManager.specialists ];
    agents.specialists.kaigen = {
      displayName = "Kaigen";
      harnesses = [
        "pi"
        "antigravity"
      ];
      domain = "Kaigen games and 3D apps: build, screenshot, publish.";
      mcpServers.kaigen.url = "https://kaigen3d.com/mcp";
    };
  };
}
