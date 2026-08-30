_: {
  flake.modules.nixos.homelab-executor = {
    services.k3s.manifests.executor.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "executor";
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "executor-data";
          namespace = "executor";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "local-path";
          resources.requests.storage = "2Gi";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "executor";
          namespace = "executor";
          labels.app = "executor";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "executor";
          template = {
            metadata.labels.app = "executor";
            spec.containers = [
              {
                name = "executor";
                image = "ghcr.io/rhyssullivan/executor-selfhost:latest";
                env = [
                  {
                    name = "EXECUTOR_WEB_BASE_URL";
                    value = "https://executor.zaza.haahr.me";
                  }
                ];
                ports = [
                  {
                    name = "http";
                    containerPort = 4788;
                  }
                ];
                resources = {
                  requests = {
                    cpu = "100m";
                    memory = "256Mi";
                  };
                  limits.memory = "1Gi";
                };
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/data";
                  }
                ];
                readinessProbe = {
                  httpGet = {
                    path = "/";
                    port = 4788;
                  };
                  initialDelaySeconds = 5;
                  periodSeconds = 10;
                };
              }
            ];
            spec.volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "executor-data";
              }
            ];
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "executor";
          namespace = "executor";
        };
        spec = {
          selector.app = "executor";
          ports = [
            {
              name = "http";
              port = 4788;
              targetPort = "http";
            }
          ];
        };
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "executor";
          namespace = "executor";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "executor.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "executor";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "executor.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
