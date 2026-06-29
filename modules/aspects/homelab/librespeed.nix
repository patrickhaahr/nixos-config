{ ... }: {
  flake.modules.nixos.homelab-librespeed = {
    services.k3s.manifests.librespeed.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "librespeed";
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "librespeed-config";
          namespace = "librespeed";
        };
        data."configs.toml" = ''
          bind_address="0.0.0.0"
          listen_port=8080
          worker_threads=1
          base_url="backend"
          ipinfo_api_key=""
          assets_path="./assets"
          stats_password=""
          redact_ip_addresses=false
          result_image_theme="dark"
          database_type="none"
          database_hostname="localhost"
          database_name="speedtest_db"
          database_username=""
          database_password=""
          database_file="speedtest.db"
          enable_tls=false
          tls_cert_file=""
          tls_key_file=""
        '';
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "librespeed";
          namespace = "librespeed";
          labels.app = "librespeed";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "librespeed";
          template = {
            metadata.labels.app = "librespeed";
            spec.containers = [
              {
                name = "librespeed";
                image = "ghcr.io/librespeed/speedtest-rust:v1.4.0";
                ports = [
                  {
                    name = "http";
                    containerPort = 8080;
                  }
                ];
                readinessProbe.httpGet = {
                  path = "/";
                  port = "http";
                };
                livenessProbe.httpGet = {
                  path = "/";
                  port = "http";
                };
                volumeMounts = [
                  {
                    name = "config";
                    mountPath = "/usr/local/bin/configs.toml";
                    subPath = "configs.toml";
                    readOnly = true;
                  }
                ];
              }
            ];
            spec.enableServiceLinks = false;
            spec.volumes = [
              {
                name = "config";
                configMap.name = "librespeed-config";
              }
            ];
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "librespeed";
          namespace = "librespeed";
        };
        spec = {
          selector.app = "librespeed";
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
          name = "librespeed";
          namespace = "librespeed";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "speedtest.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "librespeed";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "speedtest.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
