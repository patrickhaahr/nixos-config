{ ... }: {
  flake.modules.homeManager.agent-browser = { pkgs, ... }: {
    home.packages = [
      pkgs.agent-browser
      pkgs.chromium
    ];

    home.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
  };
}
