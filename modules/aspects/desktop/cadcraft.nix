{ inputs, ... }:
let
  src = inputs.cadcraft;
  version = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).workspace.package.version;
in
{
  flake.modules.nixos.cadcraft =
    { pkgs, ... }:
    let
      runtimeLibs = with pkgs; [
        libGL
        libX11
        libXcursor
        libXi
        libXrandr
        libxkbcommon
        vulkan-loader
        wayland
      ];
      package = pkgs.rustPlatform.buildRustPackage {
        pname = "cadcraft";
        inherit version src;
        cargoLock.lockFile = "${src}/Cargo.lock";
        cargoBuildFlags = [
          "-p"
          "cadcraft"
        ];
        doCheck = false;
        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.pkg-config
        ];
        postInstall = ''
          install -Dm644 packaging/linux/ai.storyteller.cadcraft.desktop -t $out/share/applications
          install -Dm644 packaging/linux/ai.storyteller.cadcraft.mime.xml -t $out/share/mime/packages
        '';
        postFixup = ''
          wrapProgram $out/bin/cadcraft --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeLibs}
        '';
      };
    in
    {
      environment.systemPackages = [ package ];
    };
}
