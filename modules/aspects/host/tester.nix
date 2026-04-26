{ self, ... }: {
  flake.modules.nixos.tester = { pkgs, ... }: {
    imports = [
      self.modules.nixos.tester-hardware
      self.modules.nixos.home-manager
      self.modules.nixos.identity-ph
      self.modules.nixos.openssh
      self.modules.nixos.niri
      self.modules.nixos.workstation
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;
    networking.hostName = "nixos";
    system.stateVersion = "25.11";
  };
}
