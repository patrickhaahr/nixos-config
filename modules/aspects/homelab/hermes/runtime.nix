_: {
  flake.modules.nixos.homelab-hermes-runtime =
    { pkgs, ... }:
    let
      brainrotPlugin = ./plugins/brainrot-summarizer;
      honchoPython = pkgs.python313.withPackages (pythonPackages: [
        (pythonPackages.buildPythonPackage {
          pname = "honcho-ai";
          version = "2.1.2";
          pyproject = true;
          src = "${
            pkgs.fetchFromGitHub {
              owner = "plastic-labs";
              repo = "honcho";
              rev = "60a15e664d7298eb790b788e95c6ca2e6bd30c80";
              hash = "sha256-FI9JO436dJD83tmyLTYSWNLSUkeErgGwId3ewI9j9ig=";
            }
          }/sdks/python";
          build-system = [ pythonPackages.setuptools ];
          dependencies = [
            pythonPackages.httpx
            pythonPackages.pydantic
          ];
          doCheck = false;
          pythonImportsCheck = [ "honcho" ];
        })
        pythonPackages.httpx
      ]);
      brainrotImageTag = builtins.substring 0 12 (
        builtins.hashString "sha256" "${brainrotPlugin}${pkgs.busybox}"
      );
      mediaToolsImageTag = builtins.substring 0 12 (
        builtins.hashString "sha256" "${pkgs.busybox}${pkgs.ffmpeg}${honchoPython}${pkgs.yt-dlp}"
      );
    in
    {
      _module.args.hermesRuntime = {
        inherit
          brainrotImageTag
          brainrotPlugin
          honchoPython
          mediaToolsImageTag
          ;
        pythonSitePackages = "${honchoPython}/${pkgs.python313.sitePackages}";
      };

      services.k3s.images = [
        (pkgs.dockerTools.buildLayeredImage {
          name = "hermes-brainrot-plugin";
          tag = brainrotImageTag;
          contents = [
            pkgs.busybox
            brainrotPlugin
          ];
          config.Env = [ "PATH=${pkgs.busybox}/bin" ];
          config.Cmd = [ "${pkgs.busybox}/bin/true" ];
        })
        (pkgs.dockerTools.buildLayeredImage {
          name = "hermes-media-tools";
          tag = mediaToolsImageTag;
          contents = [
            pkgs.busybox
            pkgs.ffmpeg
            honchoPython
            pkgs.yt-dlp
          ];
          config.Env = [ "PATH=${pkgs.busybox}/bin" ];
          config.Cmd = [ "${pkgs.busybox}/bin/true" ];
        })
      ];
    };
}
