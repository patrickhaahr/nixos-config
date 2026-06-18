{ ... }: {
  flake.modules.nixos.homelab-traefik = { config, pkgs, ... }: {
    sops.secrets.cloudflare_dns_api_token = { };

    systemd.services.k3s-traefik-cloudflare-secret = {
      description = "Sync Traefik Cloudflare DNS token into k3s";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = config.sops.secrets.cloudflare_dns_api_token.path;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.k3s ];
      script = ''
        k3s kubectl --namespace kube-system create secret generic traefik-cloudflare \
          --from-file=CF_DNS_API_TOKEN=${config.sops.secrets.cloudflare_dns_api_token.path} \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -
      '';
    };

    services.k3s.manifests.traefik-cloudflare-acme.content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChartConfig";
      metadata = {
        name = "traefik";
        namespace = "kube-system";
      };
      spec.valuesContent = ''
        deployment:
          replicas: 1

        envFrom:
          - secretRef:
              name: traefik-cloudflare

        persistence:
          enabled: true
          size: 128Mi

        certificatesResolvers:
          cloudflare:
            acme:
              email: traefik@haahr.me
              storage: /data/acme.json
              dnsChallenge:
                provider: cloudflare
                propagation:
                  delayBeforeChecks: 120s
                  disableChecks: true
                resolvers:
                  - 1.1.1.1:53
                  - 1.0.0.1:53

        ports:
          web:
            http:
              redirections:
                entryPoint:
                  to: websecure
                  scheme: https
                  permanent: true
      '';
    };
  };
}
