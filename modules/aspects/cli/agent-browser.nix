{ self, ... }: {
  flake.modules.homeManager.agent-browser =
    { pkgs, ... }:
    {
      imports = [ self.modules.homeManager.chromium ];

      home.packages = [
        (pkgs.symlinkJoin {
          name = "agent-browser-with-chromium";
          paths = [ pkgs.agent-browser ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram "$out/bin/agent-browser" \
              --set-default AGENT_BROWSER_EXECUTABLE_PATH "${pkgs.chromium}/bin/chromium"
          '';
        })
      ];
    };
}
