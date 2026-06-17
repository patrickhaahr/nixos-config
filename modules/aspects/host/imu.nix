{ self, inputs, ... }: {
  flake.modules.nixos.imu = { ... }: {
    imports = [
      inputs.nixos-wsl.nixosModules.default
      self.modules.nixos.nix-features
      self.modules.nixos.home-manager
      self.modules.nixos.identity-wsl
    ];

    networking.hostName = "imu";
    nixpkgs.hostPlatform = "x86_64-linux";

    wsl = {
      enable = true;
      defaultUser = "wsl";
    };

    system.stateVersion = "25.11";
  };
}
