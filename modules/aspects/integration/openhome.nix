{ ... }:
let
  userName = "ph";
in {
  flake.modules.nixos.openhome = { lib, pkgs, ... }: {
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
            OPENHOME_TOKEN="$(<"/home/${userName}/.config/secrets/openhome")"

            if ${lib.getExe pkgs.curl} -X POST https://openhome.haahr.me/api/ir/send \
              -H "Authorization: Bearer $OPENHOME_TOKEN" \
              -H "Content-Type: application/json" \
              -d '${builtins.toJSON { command = "bluetooth"; }}' \
              >/dev/null 2>&1; then
              exit 0
            fi

            sleep 1
          done

          exit 1
        '';
      };
    };
  };
}
