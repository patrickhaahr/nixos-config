{ self, inputs, ... }:
let
  claudeProvider.packages = [ "${inputs.pi-claude-code}" ];
  claudeModel = {
    defaultProvider = "claude-code";
    defaultModel = "claude-opus-5-5";
  };
in
{
  flake.modules.homeManager.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      settingsFormat = pkgs.formats.json { };
      managedMcp = settingsFormat.generate "pi-managed-mcp.json" {
        mcpServers = lib.mapAttrs (_: server: {
          inherit (server) command args env;
        }) config.agents.mcpServers;
      };
    in
    {
      imports = [
        self.modules.homeManager.agent-mcp
        self.modules.homeManager.agent-skills
      ];

      home = {
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi ];

        file = {
          ".pi/agent/settings.json".source = settingsFormat.generate "pi-settings.json" (
            claudeModel
            // {
              npmCommand = [ "${pkgs.nodejs_22}/bin/npm" ];
              packages = [ "npm:@ff-labs/pi-fff@0.10.3" ] ++ claudeProvider.packages;
            }
          );

          ".pi/agent/AGENTS.md".source = config.lib.agents.instructions;
        };

        activation.piManagedMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe config.lib.agents.mergeJson} ${config.home.homeDirectory}/.pi/agent/mcp.json ${managedMcp}
        '';
      };
    };

  flake.modules.homeManager.pi-specialists =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      settingsFormat = pkgs.formats.json { };
      pi = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
      specialists = lib.filterAttrs (
        _: specialist: lib.elem "pi" specialist.harnesses
      ) config.agents.specialists;
      agentDir = name: ".pi/specialists/${name}";

      command =
        name: specialist:
        let
          content = config.lib.agents.specialists.${name};
          mcpTools = map (server: "mcp__${lib.replaceStrings [ "-" ] [ "_" ] server}__*") (
            builtins.attrNames specialist.mcpServers
          );
        in
        pkgs.writeShellApplication {
          name = "pi-${name}";
          runtimeInputs = specialist.packages;
          runtimeEnv = specialist.env;
          text = ''
            export PI_CODING_AGENT_DIR=${lib.escapeShellArg "${config.home.homeDirectory}/${agentDir name}"}
            if [[ ''${1-} == mcp ]]; then exec ${lib.getExe pi} "$@"; fi
            exec ${lib.getExe pi} \
              --no-skills ${lib.optionalString (content.skills != null) "--skill ${content.skills}"} \
              --no-approve --no-context-files --no-prompt-templates ${
                lib.optionalString (mcpTools == [ ]) "--no-mcp"
              } \
              --tools ${lib.escapeShellArg (lib.concatStringsSep "," (specialist.tools ++ mcpTools))} \
              --model ${claudeModel.defaultProvider}/${claudeModel.defaultModel} \
              --append-system-prompt ${content.instructions} \
              "$@"
          '';
        };

      mcpConfig =
        name: specialist:
        settingsFormat.generate "pi-${name}-mcp.json" {
          mcpServers = lib.mapAttrs (_: server: { exposure = "direct"; } // server) specialist.mcpServers;
        };
    in
    {
      imports = [
        self.modules.homeManager.agent-skills
        self.modules.homeManager.t3code-settings
      ];

      key = "pi-specialists";

      config = {
        home = {
          packages = lib.mapAttrsToList command specialists;

          file = lib.concatMapAttrs (
            name: specialist:
            {
              "${agentDir name}/settings.json".source =
                settingsFormat.generate "pi-${name}-settings.json" claudeProvider;
              "${agentDir name}/auth.json" = {
                source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.pi/agent/auth.json";
                force = true;
              };
            }
            // lib.optionalAttrs (specialist.mcpServers != { }) {
              "${agentDir name}/mcp.json" = {
                source = mcpConfig name specialist;
                force = true;
              };
            }
          ) specialists;
        };

        t3code.providerInstances = lib.mapAttrs' (
          name: specialist:
          lib.nameValuePair "pi-${name}" {
            driver = "pi";
            displayName = "Pi ${specialist.displayName}";
            enabled = true;
            config.binaryPath = "pi-${name}";
          }
        ) specialists;
      };
    };
}
