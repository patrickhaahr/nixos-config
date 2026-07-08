{ ... }: {
  flake.modules.nixos.steam = {
    hardware.steam-hardware.enable = true;
    programs.steam.enable = true;
  };
}
