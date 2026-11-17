{ self, inputs, ... }:
{
  flake.nixosConfigurations.vivi = inputs.nixos-raspberrypi.lib.nixosSystem {
    modules = [ self.modules.nixos.vivi ];
  };
}
