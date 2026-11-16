_: {
  # nginx terminates TLS for *.zaza.haahr.me with one wildcard certificate
  # (Cloudflare DNS-01). Service aspects only declare
  # `services.nginx.virtualHosts."<name>.zaza.haahr.me"`.
  flake.modules.nixos.homelab-proxy =
    { config, lib, ... }:
    let
      domain = "zaza.haahr.me";
    in
    {
      # Re-declaring a submodule option merges into the upstream one, so every
      # vhost on this host defaults to the wildcard cert and HTTPS redirect.
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
            # The router hijacks all port-53 traffic to AdGuard, whose cache
            # never sees the fresh TXT record, so propagation checks time out.
            # Wait a fixed time instead.
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
