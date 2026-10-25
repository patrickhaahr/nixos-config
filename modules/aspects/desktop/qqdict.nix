{ inputs, ... }:
{
  flake.modules.nixos.qqdict =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.programs.qqdict.enable = lib.mkEnableOption "the qqdict push-to-talk dictation app";

      config = lib.mkIf config.programs.qqdict.enable {
        environment.systemPackages = [
          inputs.qqdict.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
    };
}
