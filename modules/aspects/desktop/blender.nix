{ self, ... }:
{
  flake.modules.nixos.blender =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.blender ];
      home-manager.sharedModules = [ self.modules.homeManager.blender ];
    };

  flake.modules.homeManager.blender =
    { pkgs, ... }:
    {
      imports = [ self.modules.homeManager.specialists ];
      agents.specialists.blender = {
        displayName = "Blender";
        harnesses = [
          "pi"
          "antigravity"
        ];
        domain = "3D assets and game worlds built from code in Blender, stylized or photoreal.";
        packages = [ pkgs.ffmpeg ];
      };
    };
}
