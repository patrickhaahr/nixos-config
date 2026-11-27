{ self, inputs, ... }:
{
  flake.modules.nixos.noop-gestures =
    { lib, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      noopGestures = inputs.noop-gestures.packages.${system}.noop-gestures;
      openhome = inputs.openhome.packages.${system}.openhome;
      toggleNoopGestures = pkgs.writeShellApplication {
        name = "toggle-noop-gestures";
        runtimeInputs = [
          pkgs.libnotify
          pkgs.systemd
        ];
        text = ''
          if systemctl --user is-active --quiet noop-gestures.service; then
            systemctl --user stop noop-gestures.service
            notify-send -a noop-gestures -h string:x-canonical-private-synchronous:noop-gestures "NOOP gestures" "Off — strap disconnected"
          else
            systemctl --user start noop-gestures.service
            notify-send -a noop-gestures -h string:x-canonical-private-synchronous:noop-gestures "NOOP gestures" "On — connecting to strap"
          fi
        '';
      };
    in
    {
      imports = [ self.modules.nixos.desktop-session ];

      environment.systemPackages = [
        noopGestures
        toggleNoopGestures
      ];

      desktop.binds."Super+G" = {
        command = [ (lib.getExe toggleNoopGestures) ];
        repeat = false;
        title = "Toggle NOOP gestures";
      };

      systemd.user.services.noop-gestures = {
        description = "NOOP wrist gesture daemon";
        after = [
          "graphical-session.target"
          "ydotoold.service"
        ];
        partOf = [ "graphical-session.target" ];
        path = [
          pkgs.ydotool
          openhome
        ];
        serviceConfig = {
          ExecStart = "${lib.getExe noopGestures} run";
          Restart = "on-failure";
          RestartSec = 3;
        };
      };
    };
}
