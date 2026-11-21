{ self, ... }:
{
  perSystem =
    { lib, system, ... }:
    let
      nika = self.nixosConfigurations.nika;
      inherit (nika) pkgs;
    in
    {
      checks = lib.optionalAttrs (system == pkgs.stdenv.hostPlatform.system) {
        niri-nika-binds =
          let
            kdl = "${nika.config.programs.niri.package}/niri-config.kdl";
          in
          pkgs.runCommand "niri-nika-binds" { } ''
            for chord in Alt_L Alt_R Control_L Control_R; do
              grep -q "^  \"Ctrl+Alt+$chord\" .*\"repeat\"=false" ${kdl}
            done
            grep -A1 '^  "Super+M"' ${kdl} | grep -q '/bin/openhome" "ir" "edifier" "mute"'
            grep -A1 '^  "Mod+H"' ${kdl} | grep -q '"focus-column-left"'

            startup=$(grep '^"spawn-at-startup"' ${kdl})
            test "$(echo "$startup" | head -n 1)" = "$(echo "$startup" | grep -m 1 'niri-focus-workspace" "2"')"
            echo "$startup" | sed -n 2,3p | grep -q '"signal-desktop"'
            echo "$startup" | sed -n 4p | grep -q 'niri-focus-workspace" "1"'

            touch "$out"
          '';
      };
    };
}
