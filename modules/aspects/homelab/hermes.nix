{ ... }: {
  flake.modules.nixos.homelab-hermes = { config, pkgs, ... }: {
    sops.secrets = {
      hermes_dashboard_basic_auth_username = { };
      hermes_dashboard_basic_auth_password = { };
      hermes_dashboard_basic_auth_secret = { };
    };

    systemd.services.k3s-hermes-dashboard-auth-secret = {
      description = "Sync Hermes dashboard auth into k3s";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = config.sops.secrets.hermes_dashboard_basic_auth_username.path;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.k3s ];
      script = ''
        k3s kubectl create namespace hermes --dry-run=client --output yaml \
          | k3s kubectl apply --filename -

        k3s kubectl --namespace hermes create secret generic hermes-dashboard-auth \
          --from-file=HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.sops.secrets.hermes_dashboard_basic_auth_username.path} \
          --from-file=HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.secrets.hermes_dashboard_basic_auth_password.path} \
          --from-file=HERMES_DASHBOARD_BASIC_AUTH_SECRET=${config.sops.secrets.hermes_dashboard_basic_auth_secret.path} \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -
      '';
    };

    services.k3s.manifests.hermes.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "hermes";
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "hermes-data";
          namespace = "hermes";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = "20Gi";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "hermes-gateway";
          namespace = "hermes";
          labels.app = "hermes-gateway";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "hermes-gateway";
          template = {
            metadata.labels.app = "hermes-gateway";
            spec.containers = [
              {
                name = "hermes-gateway";
                image = "nousresearch/hermes-agent:latest";
                args = [
                  "gateway"
                  "run"
                ];
                env = [
                  {
                    name = "HERMES_UID";
                    value = "10000";
                  }
                  {
                    name = "HERMES_GID";
                    value = "10000";
                  }
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/opt/data";
                  }
                ];
              }
            ];
            volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "hermes-data";
              }
            ];
          };
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "hermes-dashboard";
          namespace = "hermes";
          labels.app = "hermes-dashboard";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "hermes-dashboard";
          template = {
            metadata.labels.app = "hermes-dashboard";
            spec.containers = [
              {
                name = "hermes-dashboard";
                image = "nousresearch/hermes-agent:latest";
                args = [
                  "dashboard"
                  "--host"
                  "0.0.0.0"
                  "--no-open"
                ];
                env = [
                  {
                    name = "HERMES_UID";
                    value = "10000";
                  }
                  {
                    name = "HERMES_GID";
                    value = "10000";
                  }
                  {
                    name = "HERMES_DASHBOARD_PUBLIC_URL";
                    value = "https://hermes.zaza.haahr.me";
                  }
                ];
                envFrom = [
                  {
                    secretRef.name = "hermes-dashboard-auth";
                  }
                ];
                ports = [
                  {
                    name = "http";
                    containerPort = 9119;
                  }
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/opt/data";
                  }
                ];
              }
            ];
            volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "hermes-data";
              }
            ];
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "hermes-dashboard";
          namespace = "hermes";
        };
        spec = {
          selector.app = "hermes-dashboard";
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
            {
              hosts = [ "hermes.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
