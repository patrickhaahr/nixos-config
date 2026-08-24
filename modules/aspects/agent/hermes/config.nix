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
        model = {
          provider = "opencode-zen";
          default = "ox-alpha";
        };
        fallback_providers = [
          {
            provider = "openrouter";
            model = "stealth/ox-alpha";
          }
          {
            provider = "opencode-go";
            model = "gpt-5.6-luna";
          }
        ];
        agent.max_turns = 150;
        display.tool_progress = "all";
        session_reset.mode = "none";
        platforms.signal.enabled = true;
        dashboard.basic_auth = {
          username = "ph";
          password_hash = "scrypt$16384$8$1$M9G8Iaw1h0rCto5u539CDA==$Dig/ENDaIvTR2LUMb69z6FYkyV3WzS9iZKgtHQgx/B4=";
        };
      };
    };
  };
}
