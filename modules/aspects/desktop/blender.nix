_: {
  flake.modules.nixos.blender = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.blender ];
  };
}
