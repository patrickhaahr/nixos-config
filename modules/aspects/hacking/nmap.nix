_: {
  flake.modules.nixos."hacking-nmap" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.nmap ];
  };
}
