{ ... }: {
  flake.modules.homeManager.gh = {
    home.sessionVariables = {
      GH_TELEMETRY = "false";
      DO_NOT_TRACK = "true";
    };
  };
}
