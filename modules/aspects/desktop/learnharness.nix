{ lib, ... }:
let
  version = "0.3.6";
  artifact = "LearnHarness-${version}-x86_64.AppImage";
  hash = "sha256-LOobJlK1gHJgx9mnrEurLzgK5mJNfaKkseiFjhec5QA=";
in
{
  flake.modules.nixos.learnharness =
    { pkgs, ... }:
    let
      package =
        let
          base = pkgs.appimageTools.wrapType2 {
            pname = "learnharness";
            inherit version;
            src = pkgs.fetchurl {
              url = "https://github.com/amosblomqvist/learnharness/releases/download/v${version}/${artifact}";
              inherit hash;
            };
          };
          # wrapType2's output is a bare runCommand (only bin/), so the
          # AppImage-shipped learnharness.desktop/learnharness.png never reach
          # the system profile. Extract again for a launcher entry and merge.
          launcher =
            pkgs.runCommand "learnharness-desktop-${version}"
              {
                extracted = pkgs.appimageTools.extract {
                  pname = "learnharness";
                  inherit version;
                  inherit (base) src;
                };
              }
              ''
                install -Dm644 $extracted/learnharness.desktop \
                  $out/share/applications/learnharness.desktop
                install -Dm644 $extracted/learnharness.png \
                  $out/share/pixmaps/learnharness.png
              '';
        in
        pkgs.symlinkJoin {
          name = "learnharness-${version}";
          paths = [
            base
            launcher
          ];
          postBuild = ''
            cp --remove-destination "$(readlink -f "$out/share/applications/learnharness.desktop")" \
              "$out/share/applications/learnharness.desktop"
            substituteInPlace $out/share/applications/learnharness.desktop \
              --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=$out/bin/learnharness --no-sandbox %U"
          '';
        };
    in
    {
      environment.systemPackages = [ package ];
    };
}
