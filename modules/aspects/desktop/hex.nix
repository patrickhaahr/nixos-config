{ inputs, ... }:
{
  flake.modules.nixos.hex = {
    imports = [ inputs.hex.nixosModules.default ];
    programs.hex.enable = true;
  };
}
