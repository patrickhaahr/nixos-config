{ self, inputs, ... }: {
  flake.nixosConfigurations.zaza = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.modules.nixos.zaza
    ];
  };
}
