_: {
  flake.modules.nixos.doas = {
    security.sudo.enable = false;
    security.doas.enable = true;
  };
}
