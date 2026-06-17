{ self, ... }: {
  flake.modules.nixos.zaza = { pkgs, ... }: {
    imports = [
      self.modules.nixos.zaza-hardware
      self.modules.nixos.nix-features
      self.modules.nixos.home-manager
      self.modules.nixos.identity-ph-headless
      self.modules.nixos.openssh
      self.modules.nixos.tailscale
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;
    networking.hostName = "zaza";
    networking.networkmanager.enable = true;
    users.users.ph.extraGroups = [ "networkmanager" ];
    time.timeZone = "Europe/Copenhagen";
    i18n.defaultLocale = "en_DK.UTF-8";
    console.keyMap = "dk-latin1";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "25.11";
  };
}
