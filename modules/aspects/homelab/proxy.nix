_: {

  flake.modules.nixos.homelab-proxy =
    { config, lib, ... }:
    let
      domain = "zaza.haahr.me";
    in
    {

      options.services.nginx.virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            useACMEHost = lib.mkDefault domain;
            forceSSL = lib.mkDefault true;
          }
        );
      };

      config = {
        sops.secrets.cloudflare_dns_api_token = { };

        security.acme = {
          acceptTerms = true;
          defaults.email = "traefik@haahr.me";
          certs.${domain} = {
            domain = "*.${domain}";
            dnsProvider = "cloudflare";

            extraLegoFlags = [
              "--dns.propagation.wait"
              "120s"
            ];
            credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_dns_api_token.path;
            group = config.services.nginx.group;
          };
        };

        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      };
    };
}
