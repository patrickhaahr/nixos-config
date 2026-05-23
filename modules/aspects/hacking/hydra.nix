{ ... }: {
  flake.modules.nixos."hacking-hydra" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.thc-hydra ];
  };
}
