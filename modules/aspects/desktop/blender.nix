{ self, ... }:
{
  flake.modules.nixos.blender =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.blender ];
      home-manager.sharedModules = [ self.modules.homeManager.blender ];
    };

  flake.modules.homeManager.blender = {
    imports = [ self.modules.homeManager.pi-specialists ];
    pi.specialists.blender = {
      displayName = "Pi Blender";
      domain = "3D assets in Blender: modeling, materials, rigging, renders.";
    };
  };
}
