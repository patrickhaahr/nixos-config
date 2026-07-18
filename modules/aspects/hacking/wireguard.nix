_: {
  flake.modules.nixos."hacking-wireguard" = { pkgs, ... }: {
    boot.kernelModules = [ "wireguard" ];
    environment.systemPackages = [ pkgs.wireguard-tools ];
  };
}
