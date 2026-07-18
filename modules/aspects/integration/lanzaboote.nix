{ inputs, ... }: {
  flake.modules.nixos.lanzaboote = { lib, pkgs, ... }: {
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

    boot = {
      loader.systemd-boot.enable = lib.mkForce false;
      loader.efi.canTouchEfiVariables = true;
      lanzaboote = {
        enable = true;
        configurationLimit = 20;
        pkiBundle = "/var/lib/sbctl";
        autoGenerateKeys.enable = true;
        autoEnrollKeys.enable = true;
      };
    };

    environment.systemPackages = [ pkgs.sbctl ];
  };
}
