{ self, ... }:
{

  flake.modules.nixos.homelab-proxy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.homelab) domain;
      propagationWaitFlag =
        if lib.versionAtLeast pkgs.lego.version "5" then
          "--dns.propagation.wait"
        else
          "--dns.propagation-wait";
    in
    {
      imports = [ self.modules.nixos.sops ];

      options.homelab.domain = lib.mkOption {
        type = lib.types.str;
        default = "${config.networking.hostName}.haahr.me";
        readOnly = true;
        description = "Domain under which this host's homelab services are named, covered by its wildcard certificate.";
      };

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
          defaults.email = lib.mkDefault "traefik@haahr.me";
          certs.${domain} = {
            domain = "*.${domain}";
            dnsProvider = "cloudflare";

            extraLegoFlags = [
              propagationWaitFlag
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
