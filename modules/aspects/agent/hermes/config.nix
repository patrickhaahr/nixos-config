{ inputs, ... }: {
  flake.modules.homeManager.agent-hermes = {
    imports = [ inputs.hermes-agent.homeManagerModules.default ];

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
        approvals.mode = "off";
        model = {
          provider = "opencode-go";
          default = "glm-5.3-flash";
        };
        fallback_providers = [
          {
            provider = "openrouter";
            model = "z-ai/glm-5.3-flash";
          }
          {
            provider = "opencode-go";
            model = "gpt-5.6-luna";
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
        platforms.signal.enabled = true;
        dashboard.basic_auth = {
          username = "ph";
          password_hash = "scrypt$16384$8$1$M9G8Iaw1h0rCto5u539CDA==$Dig/ENDaIvTR2LUMb69z6FYkyV3WzS9iZKgtHQgx/B4=";
        };
      };
    };
  };
}
