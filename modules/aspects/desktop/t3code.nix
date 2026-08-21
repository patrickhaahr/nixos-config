let
  # Latest nightly from https://github.com/pingdotgg/t3code/releases
  version = "0.0.34-nightly.20260821.1151";
  releases = {
    x86_64-linux = {
      artifact = "T3-Code-${version}-x86_64.AppImage";
      hash = "sha256-asDSHhlKSoQsou6n1RY/FfrPbVLdYLQDbuRoOrSVKpQ=";
    };
  };
in
{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      release = releases.${system} or (throw "T3 Code is not packaged for ${system}");
    in
    {
      environment.systemPackages = [
        (pkgs.appimageTools.wrapType2 {
          pname = "t3code";
          inherit version;
          src = pkgs.fetchurl {
            url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/${release.artifact}";
            inherit (release) hash;
          };
        })
      ];
    };
}
