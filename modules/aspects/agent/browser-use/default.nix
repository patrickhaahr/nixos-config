{ inputs, self, ... }: {
  flake.modules.homeManager.browser-use =
    { pkgs, lib, ... }:
    let
  version = "0.13.10";

      src = pkgs.fetchFromGitHub {
        owner = "browser-use";
        repo = "browser-use";
        rev = version;
        hash = "sha256-2ahMEmLr8I9D1CdRf3WS7RU/SmNp2Y1z1u7CD7O9GTs=";
      };

      projectRoot = pkgs.runCommand "browser-use-src-${version}" { } ''
        cp -r ${src} $out
        chmod u+w $out
        cp ${./uv.lock} $out/uv.lock
      '';

      python = pkgs.python312;

      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = projectRoot;
      };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      pythonSet =
        (pkgs.callPackage inputs.pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              inputs.pyproject-build-systems.overlays.wheel
              overlay
            ]
          );

      browser-use-env = pythonSet.mkVirtualEnv "browser-use-env" workspace.deps.default;
    in
    {
      imports = [ self.modules.homeManager.chromium ];

      home.packages = [ browser-use-env ];

      systemd.user.services.browser-use-chromium = {
        Unit = {
          Description = "Headless chromium CDP endpoint for browser-use";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart =
            "${pkgs.chromium}/bin/chromium"
            + " --headless --remote-debugging-port=9222"
            + " --user-data-dir=%h/.cache/browser-use-chromium"
            + " --no-first-run --no-default-browser-check";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
