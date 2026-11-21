{ inputs, self, ... }: {
  flake.modules.homeManager.agent-hermes =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let

      seedSettings = pkgs.writeText "hermes-seed-settings.json" (
        builtins.toJSON {
          model = {
            provider = "openai-codex";
            default = "gpt-6.1-sol";
          };
          auxiliary.vision = {
            fallback_chain = [
              {
                provider = "opencode-go";
                model = "glm-5.3-flash";
              }
            ];
          };
          fallback_providers = [
            {
              provider = "opencode-go";
              model = "glm-5.3-flash";
            }
            {
              provider = "opencode-go";
              model = "gpt-6-luna";
            }
          ];
          moa = {
            default_preset = "default";
            presets = {
              default = {
                reference_models = [
                  {
                    provider = "opencode-go";
                    model = "deepseek-v4-flash";
                  }
                  {
                    provider = "opencode-go";
                    model = "glm-5.3-flash";
                  }
                  {
                    provider = "opencode-go";
                    model = "kimi-k2.5";
                  }
                ];
                aggregator = {
                  provider = "opencode-go";
                  model = "grok-4.6";
                };
                max_tokens = 4096;
                enabled = true;
              };
            };
          };
          agent.max_turns = 90;
          display.tool_progress = "all";

          skills.external_dirs = [ ];
          approvals.mode = "off";
          delegation = {
            subagent_auto_approve = true;
          };
          session_reset.mode = "none";
          wake_word.enabled = false;
          browser = {
            backend = "browser-use";
            cdp_url = "http://127.0.0.1:9222";
          };
          mcp_servers = {
            politikdata.url = "https://mcp.politikdata.dk/mcp";

            openhome = {
              url = "https://openhome.haahr.me/mcp";
              headers.Authorization = "Bearer \${OPENHOME_API_KEY}";
            };
          };
        }
      );

      seedConfig = pkgs.writeScript "hermes-config-seed" ''
        #!${pkgs.python3.withPackages (ps: [ ps.ruamel-yaml ])}/bin/python3
        import json, sys
        from pathlib import Path
        from ruamel.yaml import YAML

        yaml = YAML(typ="safe", pure=True)
        yaml.version = (1, 1)
        yaml.default_flow_style = False
        yaml.sort_base_mapping_type_on_output = False

        seed = json.loads(Path(sys.argv[1]).read_text())
        config_path = Path(sys.argv[2])
        existing = (yaml.load(config_path) if config_path.exists() else None) or {}

        def seed_into(base, defaults):
            result = dict(base)
            for k, v in defaults.items():
                if k not in result:
                    result[k] = v
                elif isinstance(result[k], dict) and isinstance(v, dict):
                    result[k] = seed_into(result[k], v)
            return result

        merged = seed_into(existing, seed)
        if merged != existing:
            yaml.dump(merged, config_path)
      '';
    in
    {
      imports = [
        inputs.hermes-agent.homeManagerModules.default
      ];

      home = {
        activation = {

          hermes-restart =
            lib.hm.dag.entryAfter
              [
                "reloadSystemd"
                "hermes-runtime-config"
                "hermes-signal-coach-route"
                "hermes-live-voice-plugin"
                "hermes-profile-openhome-key"
                "hermes-homelab-signal-isolation"
              ]
              ''
                if [ -S "/run/user/$(id -u)/bus" ]; then
                  run env XDG_RUNTIME_DIR="/run/user/$(id -u)" \
                    ${pkgs.systemd}/bin/systemctl --user restart \
                    hermes-agent.service hermes-backend.service
                fi
              '';

          hermes-runtime-config = lib.hm.dag.entryAfter [ "hermesAgentSetup" ] ''
            hermes_home="${config.home.homeDirectory}/.hermes"
            run ${seedConfig} ${seedSettings} "$hermes_home/config.yaml"
            run install -m 0600 ${pkgs.writeText "hermes-unmanaged" "false"} "$hermes_home/.managed"
          '';

          hermes-signal-coach-route = lib.hm.dag.entryAfter [ "hermesAgentSetup" ] ''
            route_config="${config.home.homeDirectory}/.hermes/config.yaml"
            env_file="${config.home.homeDirectory}/.hermes/.env"
            if [ -f "$route_config" ] && [ -f "$env_file" ]; then
              group_id="$(grep '^SIGNAL_COACH_GROUP_ID=' "$env_file" | cut -d= -f2- | sed 's#^group:##' || true)"
              home_group_id="$(grep '^SIGNAL_HOME_GROUP_ID=' "$env_file" | cut -d= -f2- | sed 's#^group:##' || true)"
              homelab_group_id="$(grep '^SIGNAL_HOMELAB_GROUP_ID=' "$env_file" | cut -d= -f2- | sed 's#^group:##' || true)"
              if [ -n "$group_id" ]; then
                ${pkgs.perl}/bin/perl -0pi -e "s#(?m)^  - chat_id: .*?(?=\\n    name: signal-group-coach)#  - chat_id: group:$group_id#" "$route_config"
              fi
              if [ -n "$home_group_id" ]; then
                ${pkgs.perl}/bin/perl -0pi -e "s#(?m)^  - chat_id: .*?(?=\\n    name: signal-group-home)#  - chat_id: group:$home_group_id#" "$route_config"
              fi
              if [ -n "$homelab_group_id" ]; then
                ${pkgs.perl}/bin/perl -0pi -e "s#(?m)^  - chat_id: .*?(?=\\n    name: signal-group-homelab)#  - chat_id: group:$homelab_group_id#" "$route_config"
              fi
              home_channel="$(grep '^SIGNAL_HOME_CHANNEL=' "$env_file" | cut -d= -f2- || true)"
              uwu_user_id="$(grep '^SIGNAL_ALLOWED_USERS=' "$env_file" | cut -d= -f2- | tr ',' '\n' | grep -vxF "$home_channel" | grep . || true)"
              if [ -n "$uwu_user_id" ] && [ "$(printf '%s\n' "$uwu_user_id" | wc -l)" -eq 1 ]; then
                ${pkgs.perl}/bin/perl -0pi -e "s#(?m)^  - chat_id: .*?(?=\\n    name: signal-dm-uwu)#  - chat_id: $uwu_user_id#" "$route_config"
              fi
            fi
          '';

          hermes-live-voice-plugin = lib.hm.dag.entryAfter [ "hermesAgentSetup" ] ''
            for route_config in "${config.home.homeDirectory}/.hermes/config.yaml" "${config.home.homeDirectory}/.hermes"/profiles/*/config.yaml; do
              [ -f "$route_config" ] || continue
              grep -q '^  - talk-desktop$' "$route_config" && continue
              ${pkgs.gnugrep}/bin/grep -q '^plugins:' "$route_config" ||
                printf '\nplugins:\n  enabled:\n  - talk-desktop\n' >> "$route_config"
              ${pkgs.perl}/bin/perl -0pi -e 's#^(plugins:\n  enabled:)\n(  - (?!talk-desktop))#$1\n  - talk-desktop\n$2#m; s#(plugins:\n  enabled:) \[\]$#$1\n  - talk-desktop#m' "$route_config"
            done
          '';

          hermes-profile-openhome-key = lib.hm.dag.entryAfter [ "hermesAgentSetup" ] ''
            key_file="${config.sops.secrets.openhome_api_key.path}"
            if [ -r "$key_file" ]; then
              for profile_config in "${config.home.homeDirectory}/.hermes"/profiles/*/config.yaml; do
                [ -f "$profile_config" ] || continue
                ${pkgs.gnugrep}/bin/grep -q 'OPENHOME_API_KEY' "$profile_config" || continue
                profile_env="$(dirname "$profile_config")/.env"
                tmp_env="$(mktemp "$profile_env.XXXXXX")"
                { [ -f "$profile_env" ] && ${pkgs.gnugrep}/bin/grep -v '^OPENHOME_API_KEY=' "$profile_env" || true
                  printf 'OPENHOME_API_KEY=%s\n' "$(cat "$key_file")"
                } > "$tmp_env"
                chmod 600 "$tmp_env"
                mv "$tmp_env" "$profile_env"
              done
            fi
          '';

          hermes-profile-signal-isolation = lib.hm.dag.entryAfter [ "hermesAgentSetup" ] ''
            for profile_env in "${config.home.homeDirectory}/.hermes"/profiles/*/.env; do
              [ -f "$profile_env" ] || continue
              ${pkgs.gnugrep}/bin/grep -qE '^SIGNAL_(HTTP_URL|ACCOUNT)=' "$profile_env" || continue
              tmp_env="$(mktemp "$profile_env.XXXXXX")"
              ${pkgs.gnugrep}/bin/grep -vE '^SIGNAL_(HTTP_URL|ACCOUNT)=' "$profile_env" > "$tmp_env" || true
              chmod 600 "$tmp_env"
              mv "$tmp_env" "$profile_env"
            done
          '';
        };
      };

      systemd.user.services = lib.genAttrs [ "hermes-agent" "hermes-backend" ] (_: {
        Service.Environment = lib.mkAfter [ "HERMES_MANAGED=false" ];
      });

      services.hermes-agent = {
        enable = true;
        gateway.enable = true;

        extraPythonPackages =
          let
            py = config.services.hermes-agent.package.python.pkgs;
            bare =
              p:
              p.overridePythonAttrs (
                old:
                let
                  deps = (old.dependencies or [ ]) ++ (old.propagatedBuildInputs or [ ]);
                  isPy = builtins.filter (d: d ? pythonModule) deps;
                  notPy = builtins.filter (d: !(d ? pythonModule)) deps;
                in
                {
                  dependencies = [ ];
                  propagatedBuildInputs = [ ];

                  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ isPy;
                  buildInputs = (old.buildInputs or [ ]) ++ notPy;
                  doCheck = false;
                  dontCheckRuntimeDeps = true;
                  pythonImportsCheck = [ ];
                }
              );
          in
          map (name: bare py.${name}) [
            "aiortc"
            "aioice"
            "pyee"
            "pylibsrtp"
            "google-crc32c"
            "ifaddr"
            "dnspython"
            "pyopenssl"
          ];
        backend = {
          mode = "dashboard";
          host = "127.0.0.1";
          port = 9119;
        };

        settings = {

          gateway.profile_routes = [
            {
              name = "signal-group-coach";
              platform = "signal";

              chat_id = "group:__COACH_GID__";
              profile = "coach";
            }
            {
              name = "signal-group-home";
              platform = "signal";

              chat_id = "group:__HOME_GID__";
              profile = "household";
            }
            {
              name = "signal-group-homelab";
              platform = "signal";

              chat_id = "group:__HOMELAB_GID__";
              profile = "homelab";
            }
            {
              name = "signal-dm-uwu";
              platform = "signal";

              chat_id = "__UWU_UID__";
              profile = "uwu";
            }
          ];
          platforms.signal = {
            enabled = true;

            unauthorized_dm_behavior = "ignore";
          };

          dashboard.public_url = "https://hermes.zaza.haahr.me";
          dashboard.basic_auth = {
            username = "ph";
            password_hash = "scrypt$16384$8$1$M9G8Iaw1h0rCto5u539CDA==$Dig/ENDaIvTR2LUMb69z6FYkyV3WzS9iZKgtHQgx/B4=";
          };
        };
      };
    };
}
