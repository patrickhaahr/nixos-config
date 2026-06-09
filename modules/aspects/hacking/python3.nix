{ ... }: {
  flake.modules.nixos."hacking-python3" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.python3 ];
  };
}
