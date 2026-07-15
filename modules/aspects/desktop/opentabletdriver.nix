{ ... }: {
  flake.modules.nixos.opentabletdriver = {
    hardware.opentabletdriver.enable = true;
  };
}
