{ self, inputs, ... }: {
  flake.nixosConfigurations.nika = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.modules.nixos.nika
    ];
  };
}
