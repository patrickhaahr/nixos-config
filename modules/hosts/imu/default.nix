{ self, inputs, ... }: {
  flake.nixosConfigurations.imu = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.modules.nixos.imu
    ];
  };
}
