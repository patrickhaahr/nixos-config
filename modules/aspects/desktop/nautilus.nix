_: {
  flake.modules.nixos.nautilus = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.nautilus ];
  };
}
