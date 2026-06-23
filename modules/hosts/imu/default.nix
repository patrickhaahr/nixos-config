{ self, inputs, ... }: {
  flake.nixosConfigurations.imu = inputs.nixpkgs-unstable.lib.nixosSystem {
    modules = [
      self.modules.nixos.imu
    ];
  };
}
