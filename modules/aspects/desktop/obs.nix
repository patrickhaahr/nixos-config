_: {
  flake.modules.nixos.obs =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.obs-studio ];
    };
}
