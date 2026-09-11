_: {
  flake.modules.nixos.pavucontrol = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.pavucontrol ];
  };
}
