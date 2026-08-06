_: {
  flake.modules.nixos.fritzing = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.fritzing ];
  };
}
