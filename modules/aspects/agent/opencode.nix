{ self, inputs, ... }:
let
  configDir = ".agents";
in
{
  flake.modules.homeManager.opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      opencodePackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;

      opencode = pkgs.writeShellApplication {
        name = "opencode";
        text = ''
          export OPENCODE_CONFIG_DIR="${config.home.homeDirectory}/${configDir}"
          exec ${opencodePackage}/bin/opencode2 "$@"
        '';
      };

      managedSettings = pkgs.writeText "opencode-managed-settings.json" (
        builtins.toJSON {
          "$schema" = "https://opencode.ai/v2/config.json";
          update = "disable";
          instructions = [ "AGENTS*.md" ];
          skills = [ ".skills" ];
          permissions = [
            {
              action = "*";
              resource = "*";
              effect = "allow";
            }
          ];
          mcp.servers = lib.mapAttrs (_: server: {
            type = "local";
            command = [ server.command ] ++ server.args;
            environment = server.env;
          }) config.agents.mcpServers;
        }
      );
    in
    {
      imports = [
        self.modules.homeManager.agent-mcp
        self.modules.homeManager.agent-skills
      ];

      home = {
        packages = [
          pkgs.nodejs
          pkgs.uv
          opencode
        ];
        activation.opencodeManagedSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run ${lib.getExe config.lib.agents.mergeJson} ${config.home.homeDirectory}/${configDir}/opencode.json ${managedSettings}
        '';
      };
    };
}
