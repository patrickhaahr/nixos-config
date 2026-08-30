{ self, inputs, ... }:
let
  userName = "ph";
  openhomeModule =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.services.openhome;
      openhomePackage = inputs.openhome.packages.${pkgs.stdenv.hostPlatform.system}.openhome;
      openhome = lib.getExe' openhomePackage "openhome";
      mkOpenhomeIrRetryScript =
        command:
        pkgs.writeShellScript "openhome-ir-${command}-retry" ''
          for _ in $(seq 1 30); do
            if ${openhome} ir edifier ${lib.escapeShellArg command} >/dev/null 2>&1; then
              exit 0
            fi

            sleep 1
          done

          exit 1
        '';
    in
    {
      options.services.openhome = {
        enable = lib.mkEnableOption "OpenHome integration";

        automations.enable = lib.mkEnableOption "speaker boot and shutdown automations";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ openhomePackage ];

        systemd.services = lib.mkIf cfg.automations.enable {
          openhome-bluetooth-at-boot = {
            description = "Send OpenHome bluetooth request at boot";
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              User = userName;
              ExecStart = mkOpenhomeIrRetryScript "bluetooth";
              TimeoutStartSec = 35;
            };
          };

          openhome-optical-at-shutdown = {
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
              ExecStart = mkOpenhomeIrRetryScript "optical";
              TimeoutStartSec = 35;
            };
          };
        };
      };
    };
in
{
  flake.modules.homeManager.openhome =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        defaultSopsFile = ./../../../secrets/nika.yaml;
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        secrets.openhome_api_key.path = ".config/openhome/api-key";
      };
    };

  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      openhomeEval = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          openhomeModule
          {
            services.openhome.enable = true;
            services.openhome.automations.enable = true;
            system.stateVersion = "25.11";
          }
        ];
      };
      bluetoothBootService = openhomeEval.config.systemd.services.openhome-bluetooth-at-boot;
      opticalShutdownService = openhomeEval.config.systemd.services.openhome-optical-at-shutdown;
      openhomeCli = builtins.head openhomeEval.config.environment.systemPackages;
      nika = self.nixosConfigurations.nika.config;
      phSops = nika.home-manager.users.ph.sops;
      zaza = self.nixosConfigurations.zaza.config;
      zazaHermes = zaza.home-manager.users.hermes;
      hermesSops = zazaHermes.sops;
      hermesSettings = zazaHermes.services.hermes-agent.settings;
      hermesSkillsDir = zazaHermes.home.file.".agents/skills".source;
      openhomeSkill = ./../../../agents/skills/openhome/SKILL.md;
    in
    {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        openhome-cli-package = pkgs.runCommand "openhome-cli-package" { } ''
          test '${openhomeCli}' = '${inputs.openhome.packages.${system}.openhome}'
          test -x '${openhomeCli}/bin/openhome'

          touch "$out"
        '';

        openhome-bluetooth-boot-wiring = pkgs.runCommand "openhome-bluetooth-boot-wiring" { } ''
          test '${builtins.toJSON bluetoothBootService.wantedBy}' = '["multi-user.target"]'
          test '${builtins.toJSON bluetoothBootService.wants}' = '["network-online.target"]'
          test '${builtins.toJSON bluetoothBootService.after}' = '["network-online.target"]'
          test '${builtins.toJSON bluetoothBootService.serviceConfig.TimeoutStartSec}' = '35'
          grep -F 'openhome ir edifier bluetooth' '${bluetoothBootService.serviceConfig.ExecStart}'
          grep -F 'seq 1 30' '${bluetoothBootService.serviceConfig.ExecStart}'
          grep -F 'sleep 1' '${bluetoothBootService.serviceConfig.ExecStart}'

          touch "$out"
        '';

        openhome-optical-shutdown-wiring = pkgs.runCommand "openhome-optical-shutdown-wiring" { } ''
          test '${builtins.toJSON opticalShutdownService.wantedBy}' = '["halt.target","poweroff.target","reboot.target"]'
          test '${builtins.toJSON opticalShutdownService.after}' = '["network.target"]'
          test '${builtins.toJSON opticalShutdownService.before}' = '["halt.target","poweroff.target","reboot.target"]'
          test '${builtins.toJSON opticalShutdownService.unitConfig.DefaultDependencies}' = 'false'
          test '${builtins.toJSON opticalShutdownService.serviceConfig.TimeoutStartSec}' = '35'
          grep -F 'openhome ir edifier optical' '${opticalShutdownService.serviceConfig.ExecStart}'

          touch "$out"
        '';

        openhome-nika-wiring = pkgs.runCommand "openhome-nika-wiring" { } ''
          # Nika installs the pinned OpenHome CLI package.
          test 'true' = '${
            builtins.toJSON (
              builtins.elem inputs.openhome.packages.${system}.openhome nika.environment.systemPackages
            )
          }'

          # Nika renders the API Key as a user-owned key file via SOPS. These
          # assertions inspect configuration only; the key value is never
          # decrypted, read, or printed here.
          test 'true' = '${builtins.toJSON nika.services.openhome.enable}'
          test '.config/openhome/api-key' = '${toString phSops.secrets.openhome_api_key.path}'
          case '${phSops.defaultSopsFile}' in
            *-nika.yaml) ;;
            *)
              exit 1
              ;;
          esac
          test '/home/ph/.config/sops/age/keys.txt' = '${phSops.age.keyFile}'

          touch "$out"
        '';

        openhome-zaza-wiring = pkgs.runCommand "openhome-zaza-wiring" { } ''
          # Zaza installs the pinned OpenHome CLI package without the Nika-only
          # speaker lifecycle automations.
          test 'true' = '${
            builtins.toJSON (
              builtins.elem inputs.openhome.packages.${system}.openhome zaza.environment.systemPackages
            )
          }'
          test 'true' = '${builtins.toJSON zaza.services.openhome.enable}'
          test 'false' = '${builtins.toJSON zaza.services.openhome.automations.enable}'
          test 'true' = '${builtins.toJSON (!(zaza.systemd.services ? "openhome-bluetooth-at-boot"))}'
          test 'true' = '${builtins.toJSON (!(zaza.systemd.services ? "openhome-optical-at-shutdown"))}'

          test '.hermes/.env' = '${toString hermesSops.secrets.hermes_env.path}'
          test '${./../../../secrets/hermes/env.yaml}' = '${hermesSops.defaultSopsFile}'
          test '.config/openhome/api-key' = '${toString hermesSops.secrets.openhome_api_key.path}'

          # Hermes discovers the shared declarative skills source as an
          # external skill directory, and the source ships the OpenHome skill.
          test '["/home/hermes/.agents/skills"]' = '${
            builtins.toJSON (hermesSettings.skills.external_dirs or [ ])
          }'
          test -d '${hermesSkillsDir}/openhome'
          test -f '${hermesSkillsDir}/openhome/SKILL.md'

          # The skill frontmatter parses as YAML with terminal capability
          # required, and the body carries canonical command guidance.
          ${pkgs.python3.withPackages (ps: [ ps.pyyaml ])}/bin/python3 - <<'PYEOF'
          import yaml

          text = open("${openhomeSkill}").read()
          fence = "---\n"
          assert text.startswith(fence), "missing frontmatter fence"
          end = text.index(fence, len(fence))
          frontmatter = yaml.safe_load(text[len(fence):end])
          hermes = frontmatter["metadata"]["hermes"]

          assert frontmatter["name"] == "openhome"
          assert "openhome" in frontmatter["description"].lower()
          assert hermes["requires_toolsets"] == ["terminal"]
          assert hermes["category"] and hermes["tags"]
          PYEOF
          grep -F 'openhome --help' '${openhomeSkill}'
          grep -F 'openhome health' '${openhomeSkill}'
          grep -F 'openhome lights on' '${openhomeSkill}'
          grep -F 'openhome lights off' '${openhomeSkill}'
          grep -F 'openhome ir status' '${openhomeSkill}'
          grep -F 'openhome ir edifier' '${openhomeSkill}'
          grep -F 'openhome ir lgtv' '${openhomeSkill}'
          grep -F 'openhome adguard status' '${openhomeSkill}'
          grep -F 'openhome adguard enable' '${openhomeSkill}'
          grep -F 'openhome adguard disable' '${openhomeSkill}'
          grep -F 'openhome adguard pause' '${openhomeSkill}'
          grep -F 'raw HTTP' '${openhomeSkill}'

          touch "$out"
        '';
      };
    };

  flake.modules.nixos.openhome = openhomeModule;
}
