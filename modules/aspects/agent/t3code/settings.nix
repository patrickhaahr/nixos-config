_: {
  flake.modules.homeManager.t3code-settings =
    { lib, ... }:
    {
      key = "t3code-settings";

      options.t3code.providerInstances = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = { };
        description = "T3 Code provider instances merged into its settings file at activation; T3 keeps owning the file.";
      };
    };
}
