{ ... }: {
  flake.modules.nixos.signal = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.signal-desktop ];
  };
}
