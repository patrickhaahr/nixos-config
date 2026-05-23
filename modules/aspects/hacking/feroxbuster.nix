{ ... }: {
  flake.modules.nixos."hacking-feroxbuster" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.feroxbuster ];
  };
}
