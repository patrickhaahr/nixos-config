{ self, inputs, ... }:
{
  flake.nixosConfigurations.vivi = inputs.nixos-raspberrypi.lib.nixosSystem {
    modules = [ self.modules.nixos.vivi ];
  };

  flake.modules.nixos.vivi = {
    imports = with self.modules.nixos; [
      vivi-hardware
      binary-cache
      identity-ph-vivi
      nix-features
      openssh
    ];

    networking = {
      hostName = "vivi";
      useDHCP = true;
    };

    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };

    system.stateVersion = "26.05";
  };
}
