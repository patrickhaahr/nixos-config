{ ... }: {
  flake.modules.nixos.yazi = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.yazi ];
  };
}
