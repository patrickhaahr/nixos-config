_: {
  flake.modules.nixos."hacking-wireshark" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.wireshark ];
  };
}
