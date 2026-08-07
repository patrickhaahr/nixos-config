_: {
  flake.modules.nixos.losslesscut = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.losslesscut ];
  };
}
