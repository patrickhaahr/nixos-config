{ self, ... }: {
  flake.modules.nixos.agent-hermes-host =
    { config, ... }:
    {
      imports = [
        self.modules.nixos.identity-hermes
        self.modules.nixos.agent-hermes-ssh
        self.modules.nixos.agent-hermes-dev-workspace
      ];

      services.nginx.virtualHosts = {
        "hermes.${config.homelab.domain}".locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.home-manager.users.hermes.services.hermes-agent.backend.port}";
          proxyWebsockets = true;
        };
        "hermes-api.${config.homelab.domain}".locations."/" = {
          proxyPass = "http://127.0.0.1:8642";
          proxyWebsockets = true;
        };
      };
    };
}
