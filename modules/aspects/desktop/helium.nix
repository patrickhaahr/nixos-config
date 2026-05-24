{ inputs, ... }: {
  flake.modules.nixos.helium = { lib, pkgs, config, ... }:
    let
      cfg = config.programs.helium;
      basePackage = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default;
      launcherPackage =
        if cfg.passwordStore == null then cfg.package else
        pkgs.symlinkJoin {
          name = "helium-launcher";
          paths = [ cfg.package ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram "$out/bin/helium" \
              --add-flags "--password-store=${cfg.passwordStore}"
          '';
        };
    in {
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
          description = "Value passed to Helium via --password-store. Set to null to disable local wrapping.";
        };

        launcherPackage = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "Helium package with the configured launch flags applied.";
        };
      };

      config = lib.mkIf cfg.enable {
        programs.helium.launcherPackage = launcherPackage;
        environment.systemPackages = [ launcherPackage ];
      };
    };
}
