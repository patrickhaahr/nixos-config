{ inputs, ... }: {
  flake.modules.nixos.lanzaboote = { lib, pkgs, ... }: {
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      autoGenerateKeys.enable = true;
      autoEnrollKeys.enable = true;
    };

    environment.systemPackages = [ pkgs.sbctl ];
  };
}
