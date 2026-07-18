_: {
  flake.modules.nixos."hacking-burpsuite" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.burpsuite ];
  };
}
