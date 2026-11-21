{ self, ... }:
{
  flake.modules.nixos.nautilus = { pkgs, ... }: {
    imports = [ self.modules.nixos.desktop-session ];
    environment.systemPackages = [ pkgs.nautilus ];
    desktop.binds."Mod+E".command = [ "nautilus" ];
  };
}
