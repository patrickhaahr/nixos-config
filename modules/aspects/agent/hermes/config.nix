{ inputs, self, ... }: {
  flake.modules.homeManager.agent-hermes =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.hermes-agent.homeManagerModules.default
        self.modules.homeManager.agent-hermes-wake-word
      ];

      home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

      services.hermes-agent = {
        enable = true;
        gateway.enable = true;
        backend = {
          mode = "dashboard";
          host = "0.0.0.0";
          port = 9119;
        };

        settings = {
          gateway.profile_routes = [
            {
              name = "signal-group-coach";
              platform = "signal";
              # The group ID is secret-backed in HERMES_HOME/.env (sops), never
              # in the repo: config expands ${VAR} at load time.
              chat_id = "group:__COACH_GID__";
              profile = "coach";
            }
          ];
          # The shared declarative skills source, projected to ~/.agents/skills
          # by the opencode aspect. Hermes discovers local skills (including
          # the OpenHome skill) from there as an external skill directory.
          skills.external_dirs = [ "${config.home.homeDirectory}/.agents/skills" ];
          approvals.mode = "off";
          model = {
            provider = "opencode-go";
            default = "glm-5.3-flash";
          };
          auxiliary.vision = {
            fallback_chain = [
              {
                provider = "opencode-go";
                model = "glm-5.3-flash";
              }
              {
                provider = "opencode-zen";
                model = "glm-5.3-flash";
              }
              {
                provider = "openrouter";
                model = "z-ai/glm-5.3-flash";
              }
            ];
          };
          fallback_providers = [
            {
              provider = "opencode-go";
              model = "glm-5.3-flash";
            }
            {
              provider = "opencode-zen";
              model = "glm-5.3-flash";
            }
            {
              provider = "openrouter";
              model = "z-ai/glm-5.3-flash";
            }
          ];
          delegation = {
            subagent_auto_approve = true;
          };
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
          session_reset.mode = "none";
          # Wake word: headless host has no mic — "auto" lets the desktop app
          # capture client-side and stream PCM to this backend.
          wake_word = {
            enabled = true;
            capture = "auto";
          };
          browser = {
            backend = "browser-use";
            cdp_url = "http://127.0.0.1:9222";
          };
          # Executor MCP (selfhosted k3s, see aspects/homelab/executor.nix).
          # ${EXECUTOR_API_KEY} expands from the sops-owned .hermes/.env.
          mcp_servers.executor = {
            url = "https://executor.zaza.haahr.me/mcp";
            headers.Authorization = "Bearer \${EXECUTOR_API_KEY}";
          };
          # Blender MCP (Blender + addon socket run on nika, localhost:9876).
          # The addon socket binds localhost with no auth, and nika's sshd has
          # AllowTcpForwarding off, so no -L tunnel can reach it. Instead the
          # MCP server itself runs on nika, with MCP stdio carried over ssh.
          # Quoting: sshd runs the login shell (nushell) -c, hence bash -l -c
          # with a single-quoted inner command. Passphrase-free via ssh-keys.nix.
          mcp_servers.blender = {
            command = "${pkgs.openssh}/bin/ssh";
            args = [
              "-o"
              "BatchMode=yes"
              "-o"
              "ConnectTimeout=10"
              "-o"
              "ServerAliveInterval=30"
              "-o"
              "ServerAliveCountMax=3"
              "ph@nika"
              "bash"
              "-l"
              "-c"
              "'DISABLE_TELEMETRY=true uvx blender-mcp'"
            ];
          };
          platforms.signal.enabled = true;
          dashboard.basic_auth = {
            username = "ph";
            password_hash = "scrypt$16384$8$1$M9G8Iaw1h0rCto5u539CDA==$Dig/ENDaIvTR2LUMb69z6FYkyV3WzS9iZKgtHQgx/B4=";
          };
        };
      };

      # profile_routes are parsed literally by Hermes; substitute the SOPS-backed
      # group ID after the managed config merge, without storing it in the flake.
      home.activation.hermes-signal-coach-route = lib.hm.dag.entryAfter [ "sops-nix" ] ''
        route_config="$HOME/.hermes/config.yaml"
        env_file="$HOME/.hermes/.env"
        if [ -f "$route_config" ] && [ -f "$env_file" ]; then
          group_id="$(grep '^SIGNAL_COACH_GROUP_ID=' "$env_file" | cut -d= -f2- | sed 's#^group:##')"
          if [ -n "$group_id" ]; then
            ${pkgs.perl}/bin/perl -0pi -e "s#group:__COACH_GID__#group:$group_id#g" "$route_config"
          fi
        fi
      '';
    };
}
