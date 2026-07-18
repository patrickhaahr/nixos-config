{ self, inputs, ... }: {
  flake.nixosConfigurations.loki = inputs.nixpkgs-unstable.lib.nixosSystem {
    modules = [
      self.modules.nixos.loki
    ];
  };
}
