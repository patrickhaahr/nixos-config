_: {
  flake.modules.nixos.mpv = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.mpv ];
  };
}
