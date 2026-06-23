{ ... }: {
  flake.modules.nixos.cascadia-code = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.cascadia-code ];
  };
}
