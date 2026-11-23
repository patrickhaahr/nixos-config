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

      options.pi.specialists = lib.mkOption {
        default = { };
        description = "Specialist agents, each the command `pi-<name>` and a T3 Code provider instance that see only their skill bundle, MCP servers and role prompt from `agents/specialists/<name>.md`.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              displayName = lib.mkOption { type = lib.types.str; };
              domain = lib.mkOption {
                type = lib.types.str;
                description = "The work to hand this specialist, listed in every harness's instructions.";
              };
              tools = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                  "read"
                  "write"
                  "edit"
                  "bash"
                ];
              };
              mcpServers = lib.mkOption {
                type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
                default = { };
                description = "Pi `mcp.json` server entries; tools are declared directly unless an entry sets `exposure`.";
              };
              packages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = "Executables the specialist's skills call, added to its PATH.";
              };
            };
          }
        );
      };

      config = {
        agents.extraInstructions = lib.mkIf (config.pi.specialists != { }) ''
          ## Specialists

          Specialist agents carry skills and MCP servers you lack. When a task falls in one's domain, including a test run of the specialist itself, delegate it. In T3 Code, every run goes through the provider instance `pi-<name>` (model `claude-opus-5-5` unless the task calls for another), so it is a thread the user can watch; `pi-<name> -p "<brief>"` is only for harnesses outside T3 Code. The specialist sees only the brief: the goal, input paths, output directory, deliverables and acceptance bar. Open its deliverables and check them against the brief before you report.

          ${lib.concatStrings (
            lib.mapAttrsToList (name: specialist: ''
              - `pi-${name}`: ${specialist.domain}
            '') config.pi.specialists
          )}'';

        home = {
          packages = lib.mapAttrsToList command config.pi.specialists;

          file = lib.concatMapAttrs (
            name: specialist:
            {
              "${agentDir name}/settings.json".source =
                settingsFormat.generate "pi-${name}-settings.json" claudeProvider;
            }
            // lib.optionalAttrs (specialist.mcpServers != { }) {
              "${agentDir name}/mcp.json" = {
                source = mcpConfig name specialist;
                force = true;
              };
            }
          ) config.pi.specialists;
        };

        t3code.providerInstances = lib.mapAttrs' (
          name: specialist:
          lib.nameValuePair "pi-${name}" {
            driver = "pi";
            inherit (specialist) displayName;
            enabled = true;
            config.binaryPath = "pi-${name}";
          }
        ) config.pi.specialists;
      };
    };
}
