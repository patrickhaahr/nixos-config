{ self, ... }: {
  flake.modules.nixos.agent-hermes-host = {
    imports = [
      self.modules.nixos.identity-hermes
      self.modules.nixos.agent-hermes-ssh
      self.modules.nixos.agent-hermes-dev-workspace
    ];

    services.nginx.virtualHosts = {
      "hermes.zaza.haahr.me".locations."/" = {
        proxyPass = "http://127.0.0.1:9119";
        proxyWebsockets = true;
      };
      "hermes-api.zaza.haahr.me".locations."/" = {
        proxyPass = "http://127.0.0.1:8642";
        proxyWebsockets = true;
      };
    };
  };
}
