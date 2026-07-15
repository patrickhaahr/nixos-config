{ ... }: {
  flake.modules.homeManager.agent-browser = { pkgs, ... }:
    let
      agent-browser = pkgs.symlinkJoin {
        name = "agent-browser-with-chromium";
        paths = [ pkgs.agent-browser ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/agent-browser" \
            --set-default AGENT_BROWSER_EXECUTABLE_PATH "${pkgs.chromium}/bin/chromium"
        '';
      };
    in {
      home.packages = [
        agent-browser
        pkgs.chromium
      ];
    };
}
