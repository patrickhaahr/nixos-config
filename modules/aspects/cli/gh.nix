_: {
  flake.modules.homeManager.gh = { pkgs, ... }: {
    home.packages = [ pkgs.gh ];

    home.sessionVariables = {
      GH_TELEMETRY = "false";
      DO_NOT_TRACK = "true";
    };
  };
}
