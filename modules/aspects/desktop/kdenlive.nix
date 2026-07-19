_: {
  flake.modules.nixos.kdenlive = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.kdePackages.kdenlive ];
  };
}
