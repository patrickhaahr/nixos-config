{ ... }: {
  flake.modules.nixos."hacking-hashcat" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.hashcat ];
  };
}
