_: {
  flake.modules.homeManager.gh = {
    programs.gh.enable = true;

    home.sessionVariables = {
      GH_TELEMETRY = "false";
      DO_NOT_TRACK = "true";
    };
  };
}
