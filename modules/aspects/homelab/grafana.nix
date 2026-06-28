{ ... }:
let
  grafanaDatasources = ''
    apiVersion: 1

    deleteDatasources:
      - name: prometheus
        orgId: 1

    datasources:
      - name: Loki
        type: loki
        access: proxy
        url: http://loki.grafana.svc.cluster.local:3100
        isDefault: true
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus.prometheus.svc.cluster.local:80
  '';
in {
  flake.modules.nixos.homelab-grafana = { config, pkgs, ... }: {
    sops.secrets.grafana_admin_password = { };

    systemd.services.k3s-grafana-secrets = {
      description = "Sync Grafana secrets into k3s";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = config.sops.secrets.grafana_admin_password.path;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.k3s ];
      script = ''
        k3s kubectl create namespace grafana --dry-run=client --output yaml \
          | k3s kubectl apply --filename -

        k3s kubectl --namespace grafana create secret generic grafana-admin \
          --from-file=GF_SECURITY_ADMIN_PASSWORD=${config.sops.secrets.grafana_admin_password.path} \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -
      '';
    };

    services.k3s.manifests.grafana.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "grafana";
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "grafana-datasources";
          namespace = "grafana";
        };
        data."datasources.yaml" = grafanaDatasources;
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "grafana-data";
          namespace = "grafana";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = "5Gi";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "grafana";
          namespace = "grafana";
          labels.app = "grafana";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "grafana";
          template = {
            metadata = {
              labels.app = "grafana";
              annotations."checksum/datasources" = builtins.hashString "sha256" grafanaDatasources;
            };
            spec = {
              securityContext = {
                fsGroup = 472;
                runAsUser = 472;
                runAsGroup = 472;
              };
              containers = [
                {
                  name = "grafana";
                  image = "grafana/grafana:latest";
                  env = [
                    {
                      name = "GF_SERVER_ROOT_URL";
                      value = "https://grafana.zaza.haahr.me";
                    }
                    {
                      name = "GF_SECURITY_ADMIN_USER";
                      value = "admin";
                    }
                    {
                      name = "GF_SECURITY_ADMIN_PASSWORD";
                      valueFrom.secretKeyRef = {
                        name = "grafana-admin";
                        key = "GF_SECURITY_ADMIN_PASSWORD";
                      };
                    }
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 3000;
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "data";
                      mountPath = "/var/lib/grafana";
                    }
                    {
                      name = "datasources";
                      mountPath = "/etc/grafana/provisioning/datasources/datasources.yaml";
                      subPath = "datasources.yaml";
                      readOnly = true;
                    }
                  ];
                }
              ];
              enableServiceLinks = false;
              volumes = [
                {
                  name = "data";
                  persistentVolumeClaim.claimName = "grafana-data";
                }
                {
                  name = "datasources";
                  configMap.name = "grafana-datasources";
                }
              ];
            };
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "grafana";
          namespace = "grafana";
        };
        spec = {
          selector.app = "grafana";
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
          name = "grafana";
          namespace = "grafana";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "grafana.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "grafana";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "grafana.zaza.haahr.me" ];
            }
          ];
        };
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "loki-config";
          namespace = "grafana";
        };
        data."config.yaml" = ''
          auth_enabled: false

          server:
            http_listen_port: 3100

          common:
            path_prefix: /loki
            ring:
              instance_addr: 127.0.0.1
              kvstore:
                store: inmemory
            replication_factor: 1

          schema_config:
            configs:
              - from: 2024-01-01
                store: tsdb
                object_store: filesystem
                schema: v13
                index:
                  prefix: index_
                  period: 24h

          storage_config:
            filesystem:
              directory: /loki/chunks

          limits_config:
            retention_period: 168h

          compactor:
            working_directory: /loki/compactor
            retention_enabled: true
            delete_request_store: filesystem
        '';
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "loki-data";
          namespace = "grafana";
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
          name = "loki";
          namespace = "grafana";
          labels.app = "loki";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "loki";
          template = {
            metadata.labels.app = "loki";
            spec = {
              securityContext.fsGroup = 10001;
              containers = [
                {
                  name = "loki";
                  image = "grafana/loki:latest";
                  args = [ "-config.file=/etc/loki/config.yaml" ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 3100;
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "config";
                      mountPath = "/etc/loki/config.yaml";
                      subPath = "config.yaml";
                      readOnly = true;
                    }
                    {
                      name = "data";
                      mountPath = "/loki";
                    }
                  ];
                }
              ];
              enableServiceLinks = false;
              volumes = [
                {
                  name = "config";
                  configMap.name = "loki-config";
                }
                {
                  name = "data";
                  persistentVolumeClaim.claimName = "loki-data";
                }
              ];
            };
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "loki";
          namespace = "grafana";
        };
        spec = {
          selector.app = "loki";
          ports = [
            {
              name = "http";
              port = 3100;
              targetPort = "http";
            }
          ];
        };
      }
      {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
          name = "alloy";
          namespace = "grafana";
        };
      }
      {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "ClusterRole";
        metadata.name = "alloy";
        rules = [
          {
            apiGroups = [ "" ];
            resources = [
              "namespaces"
              "nodes"
              "pods"
              "pods/log"
            ];
            verbs = [ "get" "list" "watch" ];
          }
        ];
      }
      {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "ClusterRoleBinding";
        metadata.name = "alloy";
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "alloy";
        };
        subjects = [
          {
            kind = "ServiceAccount";
            name = "alloy";
            namespace = "grafana";
          }
        ];
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "alloy-config";
          namespace = "grafana";
        };
        data."config.alloy" = ''
          discovery.kubernetes "pods" {
            role = "pod"
          }

          discovery.relabel "pod_logs" {
            targets = discovery.kubernetes.pods.targets

            rule {
              source_labels = ["__meta_kubernetes_namespace"]
              target_label  = "namespace"
            }

            rule {
              source_labels = ["__meta_kubernetes_pod_name"]
              target_label  = "pod"
            }

            rule {
              source_labels = ["__meta_kubernetes_pod_container_name"]
              target_label  = "container"
            }

            rule {
              source_labels = ["__meta_kubernetes_pod_label_app"]
              target_label  = "app"
            }
          }

          loki.source.kubernetes "pod_logs" {
            targets    = discovery.relabel.pod_logs.output
            forward_to = [loki.write.default.receiver]
          }

          loki.write "default" {
            endpoint {
              url = "http://loki.grafana.svc.cluster.local:3100/loki/api/v1/push"
            }
          }
        '';
      }
      {
        apiVersion = "apps/v1";
        kind = "DaemonSet";
        metadata = {
          name = "alloy";
          namespace = "grafana";
          labels.app = "alloy";
        };
        spec = {
          selector.matchLabels.app = "alloy";
          template = {
            metadata.labels.app = "alloy";
            spec = {
              serviceAccountName = "alloy";
              containers = [
                {
                  name = "alloy";
                  image = "grafana/alloy:latest";
                  args = [
                    "run"
                    "/etc/alloy/config.alloy"
                    "--storage.path=/var/lib/alloy/data"
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 12345;
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "config";
                      mountPath = "/etc/alloy/config.alloy";
                      subPath = "config.alloy";
                      readOnly = true;
                    }
                    {
                      name = "data";
                      mountPath = "/var/lib/alloy/data";
                    }
                  ];
                }
              ];
              enableServiceLinks = false;
              volumes = [
                {
                  name = "config";
                  configMap.name = "alloy-config";
                }
                {
                  name = "data";
                  emptyDir = { };
                }
              ];
            };
          };
        };
      }
    ];
  };
}
