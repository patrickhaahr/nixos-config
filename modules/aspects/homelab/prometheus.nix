_: {
  flake.modules.nixos.homelab-prometheus = {
    services.k3s.manifests.prometheus.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "prometheus";
      }
      {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
          name = "prometheus";
          namespace = "prometheus";
        };
      }
      {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "ClusterRole";
        metadata.name = "prometheus";
        rules = [
          {
            apiGroups = [ "" ];
            resources = [
              "endpoints"
              "nodes"
              "nodes/metrics"
              "nodes/proxy"
              "pods"
              "services"
            ];
            verbs = [
              "get"
              "list"
              "watch"
            ];
          }
          {
            nonResourceURLs = [ "/metrics" ];
            verbs = [ "get" ];
          }
        ];
      }
      {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "ClusterRoleBinding";
        metadata.name = "prometheus";
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "prometheus";
        };
        subjects = [
          {
            kind = "ServiceAccount";
            name = "prometheus";
            namespace = "prometheus";
          }
        ];
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "prometheus-config";
          namespace = "prometheus";
        };
        data."prometheus.yml" = ''
          global:
            scrape_interval: 30s
            evaluation_interval: 30s

          scrape_configs:
            - job_name: prometheus
              static_configs:
                - targets:
                    - localhost:9090

            - job_name: kubernetes-apiservers
              kubernetes_sd_configs:
                - role: endpoints
              scheme: https
              tls_config:
                ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
              relabel_configs:
                - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
                  action: keep
                  regex: default;kubernetes;https

            - job_name: kubernetes-nodes
              kubernetes_sd_configs:
                - role: node
              scheme: https
              tls_config:
                ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                insecure_skip_verify: true
              bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
              relabel_configs:
                - action: labelmap
                  regex: __meta_kubernetes_node_label_(.+)
                - target_label: __address__
                  replacement: kubernetes.default.svc:443
                - source_labels: [__meta_kubernetes_node_name]
                  regex: (.+)
                  target_label: __metrics_path__
                  replacement: /api/v1/nodes/$1/proxy/metrics

            - job_name: kubernetes-cadvisor
              kubernetes_sd_configs:
                - role: node
              scheme: https
              tls_config:
                ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                insecure_skip_verify: true
              bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
              relabel_configs:
                - action: labelmap
                  regex: __meta_kubernetes_node_label_(.+)
                - target_label: __address__
                  replacement: kubernetes.default.svc:443
                - source_labels: [__meta_kubernetes_node_name]
                  regex: (.+)
                  target_label: __metrics_path__
                  replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor

            - job_name: kubernetes-service-endpoints
              kubernetes_sd_configs:
                - role: endpoints
              relabel_configs:
                - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
                  action: keep
                  regex: true
                - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
                  action: replace
                  target_label: __scheme__
                  regex: (https?)
                - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
                  action: replace
                  target_label: __metrics_path__
                  regex: (.+)
                - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
                  action: replace
                  target_label: __address__
                  regex: ([^:]+)(?::\d+)?;(\d+)
                  replacement: $1:$2
                - action: labelmap
                  regex: __meta_kubernetes_service_label_(.+)
                - source_labels: [__meta_kubernetes_namespace]
                  action: replace
                  target_label: kubernetes_namespace
                - source_labels: [__meta_kubernetes_service_name]
                  action: replace
                  target_label: kubernetes_name

            - job_name: kubernetes-pods
              kubernetes_sd_configs:
                - role: pod
              relabel_configs:
                - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
                  action: keep
                  regex: true
                - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
                  action: replace
                  target_label: __scheme__
                  regex: (https?)
                - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
                  action: replace
                  target_label: __metrics_path__
                  regex: (.+)
                - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
                  action: replace
                  regex: ([^:]+)(?::\d+)?;(\d+)
                  replacement: $1:$2
                  target_label: __address__
                - action: labelmap
                  regex: __meta_kubernetes_pod_label_(.+)
                - source_labels: [__meta_kubernetes_namespace]
                  action: replace
                  target_label: kubernetes_namespace
                - source_labels: [__meta_kubernetes_pod_name]
                  action: replace
                  target_label: kubernetes_pod_name
        '';
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "prometheus-data";
          namespace = "prometheus";
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
          name = "prometheus";
          namespace = "prometheus";
          labels.app = "prometheus";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "prometheus";
          template = {
            metadata.labels.app = "prometheus";
            spec = {
              serviceAccountName = "prometheus";
              securityContext.fsGroup = 65534;
              containers = [
                {
                  name = "prometheus";
                  image = "prom/prometheus:latest";
                  args = [
                    "--config.file=/etc/prometheus/prometheus.yml"
                    "--storage.tsdb.path=/prometheus"
                    "--storage.tsdb.retention.time=30d"
                    "--web.enable-lifecycle"
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 9090;
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "config";
                      mountPath = "/etc/prometheus/prometheus.yml";
                      subPath = "prometheus.yml";
                      readOnly = true;
                    }
                    {
                      name = "data";
                      mountPath = "/prometheus";
                    }
                  ];
                }
              ];
              enableServiceLinks = false;
              volumes = [
                {
                  name = "config";
                  configMap.name = "prometheus-config";
                }
                {
                  name = "data";
                  persistentVolumeClaim.claimName = "prometheus-data";
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
          name = "prometheus";
          namespace = "prometheus";
        };
        spec = {
          selector.app = "prometheus";
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
          name = "prometheus";
          namespace = "prometheus";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "prometheus.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "prometheus";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "prometheus.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
