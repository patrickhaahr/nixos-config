_: {
  flake.modules.nixos."hacking-7zz" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs._7zz ];
  };
}
