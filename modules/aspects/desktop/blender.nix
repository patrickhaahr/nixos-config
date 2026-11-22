{ self, inputs, ... }:
{
  flake.modules.nixos.blender =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.blender ];
      home-manager.sharedModules = [ self.modules.homeManager.blender ];
    };

  flake.modules.homeManager.blender =
    { config, pkgs, ... }:
    let
      specialist = config.lib.agents.specialists.blender;
      pi = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
    in
    {
      imports = [
        self.modules.homeManager.agent-skills
        self.modules.homeManager.t3code-settings
      ];

      t3code.providerInstances.pi-blender = {
        driver = "pi";
        displayName = "Pi Blender";
        enabled = true;
        config.binaryPath = "pi-blender";
      };

      home.packages = [
        (pkgs.writeShellApplication {
          name = "pi-blender";
          text = ''
            exec ${pi}/bin/pi \
              --no-skills --skill ${specialist.skills} \
              --no-context-files --no-mcp --no-prompt-templates \
              --tools read,write,edit,bash \
              --append-system-prompt ${specialist.instructions} \
              "$@"
          '';
        })
      ];
    };
}
