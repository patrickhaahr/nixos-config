{ self, inputs, ... }: {
  flake.modules.nixos.imu = { ... }: {
    imports = [
      inputs.nixos-wsl.nixosModules.default
      self.modules.nixos.nix-features
      self.modules.nixos.home-manager
      self.modules.nixos.identity-ph-headless
      self.modules.nixos.tailscale
    ];

    networking.hostName = "imu";
    nixpkgs.hostPlatform = "x86_64-linux";

    wsl = {
      enable = true;
      defaultUser = "ph";
    };

    home-manager.users.ph.imports = [
      self.modules.homeManager.agent-browser
    ];

    system.stateVersion = "25.11";
  };
}
