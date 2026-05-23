{ ... }: {
  flake.modules.nixos."hacking-ffuf" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.ffuf ];
  };
}
