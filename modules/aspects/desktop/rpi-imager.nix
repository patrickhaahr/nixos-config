_: {
  flake.modules.nixos.rpi-imager = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.rpi-imager ];
  };
}
