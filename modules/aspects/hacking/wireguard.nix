{ ... }: {
  flake.modules.nixos."hacking-wireguard" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.wireguard-tools ];
  };
}
