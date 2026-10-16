{ inputs, ... }: {
  flake.modules.nixos.helium =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.programs.helium;
      basePackage = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default;
      launcherPackage = pkgs.symlinkJoin {
        name = "helium-launcher";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        # Helium needs the system Vulkan loader and driver manifests for native WebGPU.
        postBuild = ''
          wrapProgram "$out/bin/helium" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.vulkan-loader ]}" \
            --prefix XDG_DATA_DIRS : "/run/opengl-driver/share" ${
              lib.optionalString (cfg.passwordStore != null) (
                "--add-flags " + lib.escapeShellArg "--password-store=${cfg.passwordStore}"
              )
            }
        '';
      };
    in
    {
      options.programs.helium = {
        enable = lib.mkEnableOption "Helium browser";

        package = lib.mkOption {
          type = lib.types.package;
          default = basePackage;
          defaultText = lib.literalExpression "inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default";
          description = "Base Helium package before local launch wrapping.";
        };

        passwordStore = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "basic";
          example = "gnome-libsecret";
          description = "Value passed to Helium via --password-store. Set to null to omit the flag.";
        };

        launcherPackage = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "Helium package with Vulkan runtime paths and configured launch flags applied.";
        };
      };

      config = lib.mkMerge [
        {
          programs.helium.enable = lib.mkDefault true;
        }
        (lib.mkIf cfg.enable {
          programs.helium.launcherPackage = launcherPackage;
          environment.systemPackages = [ launcherPackage ];
        })
      ];
    };
}
