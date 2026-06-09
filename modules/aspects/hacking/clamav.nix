{ ... }: {
  flake.modules.nixos."hacking-clamav" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.clamav ];
  };
}
