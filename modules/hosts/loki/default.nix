{ self, inputs, ... }: {
  flake.nixosConfigurations.loki = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.modules.nixos.loki
    ];
  };
}
