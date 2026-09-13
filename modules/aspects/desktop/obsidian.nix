_: {
  flake.modules.nixos.obsidian = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.obsidian ];
  };
}
