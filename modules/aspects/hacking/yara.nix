_: {
  flake.modules.nixos."hacking-yara" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.yara ];
  };
}
