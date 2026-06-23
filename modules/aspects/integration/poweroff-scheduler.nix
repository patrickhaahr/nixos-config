{ ... }: {
  flake.modules.nixos.poweroff-scheduler = { pkgs, ... }:
    let
      fiveMinuteWarning = pkgs.writeShellScript "poweroff-warning-five-minutes" ''
        exec ${pkgs.libnotify}/bin/notify-send \
          --app-name "systemd" \
          --urgency=critical \
          --expire-time=300000 \
          "Automatic poweroff" \
          "This PC will power off at 23:00 in 5 minutes."
      '';

      oneMinuteWarning = pkgs.writeShellScript "poweroff-warning-one-minute" ''
        exec ${pkgs.libnotify}/bin/notify-send \
          --app-name "systemd" \
          --urgency=critical \
          --expire-time=60000 \
          "Automatic poweroff" \
          "This PC will power off at 23:00 in 1 minute."
      '';
    in {
      systemd.user.services.poweroff-warning-five-minutes = {
        description = "Send 5-minute poweroff warning";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = fiveMinuteWarning;
        };
      };

      systemd.user.timers.poweroff-warning-five-minutes = {
        description = "Daily 5-minute warning before poweroff";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 22:55:00";
          Unit = "poweroff-warning-five-minutes.service";
        };
      };

      systemd.user.services.poweroff-warning-one-minute = {
        description = "Send 1-minute poweroff warning";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = oneMinuteWarning;
        };
      };

      systemd.user.timers.poweroff-warning-one-minute = {
        description = "Daily 1-minute warning before poweroff";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 22:59:00";
          Unit = "poweroff-warning-one-minute.service";
        };
      };

      systemd.services.scheduled-poweroff = {
        description = "Power off the system at 23:00";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl poweroff";
        };
      };

      systemd.timers.scheduled-poweroff = {
        description = "Daily poweroff at 23:00";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 23:00:00";
          Unit = "scheduled-poweroff.service";
        };
      };
    };
}
