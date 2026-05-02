{ self, ... }: {
  flake.modules.nixos.nika = { pkgs, ... }: {
    imports = [
      self.modules.nixos.nika-hardware
      self.modules.nixos.home-manager
      self.modules.nixos.identity-ph
      self.modules.nixos.openlinkhub
      self.modules.nixos.openssh
      self.modules.nixos.niri
      self.modules.nixos.steam
      self.modules.nixos.sunshine
      self.modules.nixos."niri-dp1-1080p"
      self.modules.nixos.workstation
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;
    networking.hostName = "nika";
    system.stateVersion = "25.11";
  };
}
