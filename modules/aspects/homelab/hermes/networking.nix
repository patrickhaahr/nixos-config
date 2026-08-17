_: {
  flake.modules.nixos.homelab-hermes-networking = {
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8642 ];

    services.k3s.manifests.hermes-networking.content = [
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "hermes-dashboard";
          namespace = "hermes";
        };
        spec = {
          selector.app = "hermes";
          ports = [
            {
              name = "http";
              port = 80;
              targetPort = "http";
            }
          ];
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "hermes-api-server";
          namespace = "hermes";
        };
        spec = {
          type = "LoadBalancer";
          selector.app = "hermes";
          ports = [
            {
              name = "http";
              port = 8642;
              targetPort = "api-server";
            }
          ];
        };
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "hermes-dashboard";
          namespace = "hermes";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "hermes.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "hermes-dashboard";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            { hosts = [ "hermes.zaza.haahr.me" ]; }
          ];
        };
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "hermes-api-server";
          namespace = "hermes";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "hermes-api.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "hermes-api-server";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            { hosts = [ "hermes-api.zaza.haahr.me" ]; }
          ];
        };
      }
    ];
  };
}
