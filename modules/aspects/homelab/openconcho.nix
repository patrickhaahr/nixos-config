{ ... }: {
  flake.modules.nixos.homelab-openconcho = {
    services.k3s.manifests.openconcho.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "openconcho";
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "openconcho";
          namespace = "openconcho";
          labels.app = "openconcho";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "openconcho";
          template = {
            metadata.labels.app = "openconcho";
            spec = {
              securityContext = {
                runAsNonRoot = true;
                runAsUser = 101;
                runAsGroup = 101;
                fsGroup = 101;
                seccompProfile.type = "RuntimeDefault";
              };
              containers = [
                {
                  name = "openconcho";
                  image = "ghcr.io/offendingcommit/openconcho-web:latest";
                  ports = [
                    {
                      name = "http";
                      containerPort = 8080;
                    }
                  ];
                  env = [
                    {
                      name = "OPENCONCHO_DEFAULT_HONCHO_URL";
                      value = "https://honcho.zaza.haahr.me";
                    }
                    {
                      name = "OPENCONCHO_UPSTREAM_ALLOWLIST";
                      value = "honcho.zaza.haahr.me";
                    }
                  ];
                  readinessProbe = {
                    httpGet = {
                      path = "/healthz";
                      port = "http";
                    };
                    initialDelaySeconds = 5;
                    periodSeconds = 10;
                    timeoutSeconds = 5;
                    failureThreshold = 3;
                  };
                  livenessProbe = {
                    httpGet = {
                      path = "/healthz";
                      port = "http";
                    };
                    initialDelaySeconds = 30;
                    periodSeconds = 30;
                    timeoutSeconds = 5;
                    failureThreshold = 3;
                  };
                  securityContext = {
                    allowPrivilegeEscalation = false;
                    capabilities.drop = [ "ALL" ];
                  };
                }
              ];
              enableServiceLinks = false;
            };
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "openconcho";
          namespace = "openconcho";
        };
        spec = {
          selector.app = "openconcho";
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
          name = "openconcho";
          namespace = "openconcho";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "openconcho.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "openconcho";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "openconcho.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
