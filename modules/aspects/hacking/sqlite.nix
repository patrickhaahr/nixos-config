{ ... }: {
  flake.modules.nixos."hacking-sqlite" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.sqlite ];
  };
}
