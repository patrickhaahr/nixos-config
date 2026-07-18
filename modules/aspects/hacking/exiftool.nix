_: {
  flake.modules.nixos."hacking-exiftool" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.exiftool ];
  };
}
