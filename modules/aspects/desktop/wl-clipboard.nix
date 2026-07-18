_: {
  flake.modules.nixos.wl-clipboard = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.wl-clipboard ];
  };
}
