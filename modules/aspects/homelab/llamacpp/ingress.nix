_: {
  flake.modules.nixos.homelab-llamacpp-nika-ingress = {
    services.k3s.manifests.llamacpp-nika-ingress.content = [
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "llamacpp-nika";
          namespace = "llamacpp";
        };
        spec.ports = [
          {
            name = "http";
            port = 8080;
            targetPort = 8080;
          }
        ];
      }
      {
        apiVersion = "v1";
        kind = "Endpoints";
        metadata = {
          name = "llamacpp-nika";
          namespace = "llamacpp";
        };
        subsets = [
          {
            addresses = [
              { ip = "100.75.6.21"; }
            ];
            ports = [
              {
                name = "http";
                port = 8080;
              }
            ];
          }
        ];
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "llamacpp-nika";
          namespace = "llamacpp";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "llamacpp.nika.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "llamacpp-nika";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            { hosts = [ "llamacpp.nika.haahr.me" ]; }
          ];
        };
      }
    ];
  };
}
