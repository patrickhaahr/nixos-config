{ self, inputs, ... }:
{
  flake.modules.homeManager.antigravity =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.modules.homeManager.agent-mcp
        self.modules.homeManager.agent-skills
      ];

      programs.antigravity-cli = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli;
        mutableSettings = true;
        mcpServers = lib.mapAttrs (_: server: {
          inherit (server) command args env;
        }) config.agents.mcpServers;
      };

      home = {
        sessionVariables.AGY_CLI_DISABLE_AUTO_UPDATE = "true";
        file = {
          ".gemini/GEMINI.md".source = config.lib.agents.instructions;
          ".gemini/config/skills" = {
            inherit (config.home.file.".agents/skills") source;
            recursive = true;
          };
        };
      };
    };

  flake.modules.homeManager.antigravity-specialists =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      settingsFormat = pkgs.formats.json { };
      specialists = lib.filterAttrs (
        _: specialist: lib.elem "antigravity" specialist.harnesses
      ) config.agents.specialists;
      homeDir = config.home.homeDirectory;
      specialistDir = name: ".antigravity/specialists/${name}";
      mainInstance = "antigravity";
      mainProfile = "${homeDir}/.t3/userdata/providers/antigravity/${builtins.hashString "sha256" mainInstance}";
      token = "antigravity-acp/antigravity-oauth-token";

      command =
        name: specialist:
        let
          mcpConfig = settingsFormat.generate "agy-${name}-mcp.json" { inherit (specialist) mcpServers; };
        in
        pkgs.writeShellApplication {
          name = "agy";
          runtimeEnv = specialist.env;
          runtimeInputs = specialist.packages ++ [ pkgs.coreutils ];
          text = ''
            export HOME=${lib.escapeShellArg homeDir}
            args=("$@")
            for i in "''${!args[@]}"; do
              [[ ''${args[i]} == --gemini-dir ]] || continue
              profile=''${args[i + 1]}
              mkdir -p "$profile/config" "$profile/antigravity-acp"
              install -m 600 ${mcpConfig} "$profile/config/mcp_config.json"
              ln -sfn ${lib.escapeShellArg "${mainProfile}/${token}"} "$profile/${token}"
            done
            exec ${
              lib.getExe inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli
            } "$@"
          '';
        };
    in
    {
      key = "antigravity-specialists";

      imports = [
        self.modules.homeManager.agent-skills
        self.modules.homeManager.t3code-settings
      ];

      config = {
        home.file = lib.concatMapAttrs (
          name: specialist:
          let
            content = config.lib.agents.specialists.${name};
          in
          {
            "${specialistDir name}/agy".source = lib.getExe (command name specialist);
            "${specialistDir name}/.gemini/GEMINI.md".source = content.instructions;
          }
          // lib.optionalAttrs (content.skills != null) {
            "${specialistDir name}/.gemini/config/skills".source = content.skills;
          }
        ) specialists;

        t3code.providerInstances = lib.mapAttrs' (
          name: specialist:
          lib.nameValuePair "agy-${name}" {
            driver = "antigravity";
            displayName = "Antigravity ${specialist.displayName}";
            enabled = true;
            environment = [
              {
                name = "HOME";
                value = "${homeDir}/${specialistDir name}";
                sensitive = false;
              }
            ];
            config.binaryPath = "${homeDir}/${specialistDir name}/agy";
          }
        ) specialists;
      };
    };
}
