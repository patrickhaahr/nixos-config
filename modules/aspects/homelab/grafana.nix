_: {

  flake.modules.nixos.homelab-grafana =
    { config, ... }:
    let
      lokiPort = 3100;
      grafanaPort = 3000;
      domain = "grafana.${config.homelab.domain}";
      secret = name: "$__file{${config.sops.secrets.${name}.path}}";
    in
    {
      sops.secrets = {
        grafana_admin_password.owner = "grafana";
        grafana_secret_key.owner = "grafana";
      };

      services = {
        grafana = {
          enable = true;
          settings = {
            server = {
              http_addr = "127.0.0.1";
              http_port = grafanaPort;
              inherit domain;
              root_url = "https://${domain}/";
            };
            security = {
              admin_password = secret "grafana_admin_password";
              secret_key = secret "grafana_secret_key";
            };
            analytics.reporting_enabled = false;
          };
          provision.datasources.settings.datasources = [
            {
              name = "Loki";
              type = "loki";
              url = "http://127.0.0.1:${toString lokiPort}";
              isDefault = true;
            }
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:${toString config.services.prometheus.port}";
            }
          ];
        };

        loki = {
          enable = true;
          configuration = {
            auth_enabled = false;
            server = {
              http_listen_address = "127.0.0.1";
              http_listen_port = lokiPort;
              grpc_listen_address = "127.0.0.1";
            };

            frontend.address = "127.0.0.1";
            common = {
              path_prefix = config.services.loki.dataDir;
              ring = {
                instance_addr = "127.0.0.1";
                kvstore.store = "inmemory";
              };
              replication_factor = 1;
            };
            schema_config.configs = [
              {
                from = "2024-01-01";
                store = "tsdb";
                object_store = "filesystem";
                schema = "v13";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];
            storage_config.filesystem.directory = "${config.services.loki.dataDir}/chunks";
            limits_config.retention_period = "168h";
            compactor = {
              working_directory = "${config.services.loki.dataDir}/compactor";
              retention_enabled = true;
              delete_request_store = "filesystem";
            };
            analytics.reporting_enabled = false;
          };
        };

        alloy = {
          enable = true;
          extraFlags = [ "--server.http.listen-addr=127.0.0.1:12345" ];
        };
        nginx.virtualHosts.${domain}.locations."/" = {
          proxyPass = "http://127.0.0.1:${toString grafanaPort}";
          proxyWebsockets = true;
        };
      };

      environment.etc."alloy/config.alloy".text = ''
        loki.relabel "journal" {
          forward_to = []
          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
          rule {
            source_labels = ["__journal_container_name"]
            target_label  = "container"
          }
          rule {
            source_labels = ["__journal_priority_keyword"]
            target_label  = "level"
          }
        }

        loki.source.journal "journal" {
          max_age       = "12h"
          relabel_rules = loki.relabel.journal.rules
          labels        = { host = "zaza" }
          forward_to    = [loki.write.default.receiver]
        }

        loki.write "default" {
          endpoint {
            url = "http://127.0.0.1:${toString lokiPort}/loki/api/v1/push"
          }
        }
      '';
    };
}
