_: {
  flake.modules.nixos.zed = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.zed-editor ];
  };
}
