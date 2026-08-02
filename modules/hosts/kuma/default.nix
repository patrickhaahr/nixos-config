{ self, inputs, ... }: {
  flake.nixosConfigurations.kuma = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.modules.nixos.kuma
    ];
  };
}
