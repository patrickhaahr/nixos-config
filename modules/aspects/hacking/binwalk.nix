{ ... }: {
  flake.modules.nixos."hacking-binwalk" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.binwalk ];
  };
}
