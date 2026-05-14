{ inputs, ... }:
let
  userName = "ph";
  openhomeModule = { lib, pkgs, config, ... }:
    let
      cfg = config.services.openhome;
      mkOpenhomeIr = command: pkgs.writeShellScriptBin "openhome-ir-${command}" ''
        OPENHOME_TOKEN="$(<"/home/${userName}/.config/secrets/openhome")"
        exec ${lib.getExe pkgs.curl} -X POST https://openhome.haahr.me/api/ir/send \
          -H "Authorization: Bearer $OPENHOME_TOKEN" \
          -H "Content-Type: application/json" \
          -d '${builtins.toJSON { inherit command; }}'
      '';
      mkOpenhomeIrRetryScript = name: command: pkgs.writeShellScript name ''
        for _ in $(seq 1 30); do
          if ${lib.getExe (mkOpenhomeIr command)} >/dev/null 2>&1; then
            exit 0
          fi

          sleep 1
        done

        exit 1
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
            ExecStart = mkOpenhomeIrRetryScript "openhome-bluetooth-at-boot" "bluetooth";
          };
        };

        systemd.services.openhome-optical-at-shutdown = {
          description = "Send OpenHome optical request at shutdown";
          wantedBy = [
            "halt.target"
            "poweroff.target"
            "reboot.target"
          ];
          after = [ "network.target" ];
          before = [
            "halt.target"
            "poweroff.target"
            "reboot.target"
          ];
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            User = userName;
            ExecStart = mkOpenhomeIrRetryScript "openhome-optical-at-shutdown" "optical";
            TimeoutStartSec = 35;
          };
        };
      };
    };
in {
  perSystem = { lib, pkgs, system, ... }:
    let
      openhomeEval = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          openhomeModule
          {
            services.openhome.enable = true;
          }
        ];
      };
      opticalShutdownService = openhomeEval.config.systemd.services.openhome-optical-at-shutdown;
    in {
        checks = lib.optionalAttrs pkgs.stdenv.isLinux {
          openhome-optical-shutdown-wiring = pkgs.runCommand "openhome-optical-shutdown-wiring" { } ''
            test '${builtins.toJSON opticalShutdownService.wantedBy}' = '["halt.target","poweroff.target","reboot.target"]'
            test '${builtins.toJSON opticalShutdownService.after}' = '["network.target"]'
            test '${builtins.toJSON opticalShutdownService.before}' = '["halt.target","poweroff.target","reboot.target"]'
            test '${builtins.toJSON opticalShutdownService.unitConfig.DefaultDependencies}' = 'false'
            test '${builtins.toJSON opticalShutdownService.serviceConfig.TimeoutStartSec}' = '35'
            case '${opticalShutdownService.serviceConfig.ExecStart}' in
            *openhome-optical-at-shutdown*) ;;
            *)
              exit 1
              ;;
          esac

          touch "$out"
        '';
      };
    };

  flake.modules.nixos.openhome = openhomeModule;
}
