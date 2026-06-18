{ ... }: {
  flake.modules.nixos.homelab-excalidraw = {
    services.k3s.manifests.excalidraw.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "excalidraw";
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "excalidraw";
          namespace = "excalidraw";
          labels.app = "excalidraw";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "excalidraw";
          template = {
            metadata.labels.app = "excalidraw";
            spec.containers = [
              {
                name = "excalidraw";
                image = "excalidraw/excalidraw:latest";
                ports = [
                  {
                    name = "http";
                    containerPort = 80;
                  }
                ];
              }
            ];
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "excalidraw";
          namespace = "excalidraw";
        };
        spec = {
          selector.app = "excalidraw";
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
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "excalidraw";
          namespace = "excalidraw";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "excalidraw.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "excalidraw";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "excalidraw.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
