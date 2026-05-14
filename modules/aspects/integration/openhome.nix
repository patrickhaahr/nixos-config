{ ... }:
let
  userName = "ph";
in {
  flake.modules.nixos.openhome = { lib, pkgs, config, ... }:
    let
      cfg = config.services.openhome;
      mkOpenhomeIr = command: pkgs.writeShellScriptBin "openhome-ir-${command}" ''
        OPENHOME_TOKEN="$(<"/home/${userName}/.config/secrets/openhome")"
        exec ${lib.getExe pkgs.curl} -X POST https://openhome.haahr.me/api/ir/send \
          -H "Authorization: Bearer $OPENHOME_TOKEN" \
          -H "Content-Type: application/json" \
          -d '${builtins.toJSON { inherit command; }}'
      '';
    in {
      options.services.openhome.enable = lib.mkEnableOption "OpenHome integration";

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          (mkOpenhomeIr "mute")
          (mkOpenhomeIr "bluetooth")
          (mkOpenhomeIr "optical")
          (mkOpenhomeIr "volume-up")
          (mkOpenhomeIr "volume-down")
        ];

        systemd.services.openhome-bluetooth-at-boot = {
          description = "Send OpenHome bluetooth request at boot";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = userName;
            ExecStart = pkgs.writeShellScript "openhome-bluetooth-at-boot" ''
              for _ in $(seq 1 30); do
                if ${lib.getExe (mkOpenhomeIr "bluetooth")} \
                  >/dev/null 2>&1; then
                  exit 0
                fi

                sleep 1
              done

              exit 1
            '';
          };
        };

        systemd.services.openhome-optical-at-shutdown = {
          description = "Send OpenHome optical request at shutdown";
          wantedBy = [ "poweroff.target" ];
          before = [ "poweroff.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = userName;
            ExecStart = pkgs.writeShellScript "openhome-optical-at-shutdown" ''
              exec ${lib.getExe (mkOpenhomeIr "optical")} >/dev/null 2>&1
            '';
          };
        };
      };
    };
}
