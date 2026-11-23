{ self, ... }:
{
  flake.modules.homeManager.t3code-settings =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      instances = pkgs.writeText "t3code-provider-instances.json" (
        builtins.toJSON { providerInstances = config.t3code.providerInstances; }
      );
    in
    {
      imports = [ self.modules.homeManager.agent-mcp ];

      key = "t3code-settings";

      options.t3code.providerInstances = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = { };
        description = "T3 Code provider instances merged into its settings file at activation; T3 keeps owning the file.";
      };

      config.home.activation.t3codeProviderInstances = lib.mkIf (config.t3code.providerInstances != { }) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe config.lib.agents.mergeJson} ${lib.escapeShellArg "${config.home.homeDirectory}/.t3/userdata/settings.json"} ${instances}
        ''
      );
    };
}
