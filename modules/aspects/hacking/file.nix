{ ... }: {
  flake.modules.nixos."hacking-file" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.file ];
  };
}
