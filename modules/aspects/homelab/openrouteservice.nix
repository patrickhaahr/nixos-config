_: {
  flake.modules.nixos.homelab-openrouteservice = {
    services.k3s.manifests.openrouteservice.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "openrouteservice";
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "ors-data";
          namespace = "openrouteservice";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "local-path";
          resources.requests.storage = "20Gi";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "openrouteservice";
          namespace = "openrouteservice";
          labels.app = "openrouteservice";
        };
        spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "openrouteservice";
          template = {
            metadata.labels.app = "openrouteservice";
            spec = {
              enableServiceLinks = false;
              initContainers = [
                {
                  name = "fetch-denmark-osm";
                  image = "busybox:1.37.0";
                  command = [
                    "sh"
                    "-ec"
                    ''
                      mkdir -p /home/ors/files
                      if [ ! -s /home/ors/files/denmark-latest.osm.pbf ]; then
                        wget -O /home/ors/files/denmark-latest.osm.pbf.tmp \
                          https://download.geofabrik.de/europe/denmark-latest.osm.pbf
                        mv /home/ors/files/denmark-latest.osm.pbf.tmp /home/ors/files/denmark-latest.osm.pbf
                      fi
                    ''
                  ];
                  volumeMounts = [
                    {
                      name = "data";
                      mountPath = "/home/ors";
                    }
                  ];
                }
              ];
              containers = [
                {
                  name = "openrouteservice";
                  image = "heigit/openrouteservice:v10.0.1";
                  env = [
                    {
                      name = "XMS";
                      value = "4g";
                    }
                    {
                      name = "XMX";
                      value = "6g";
                    }
                    {
                      name = "ors.engine.profile_default.build.source_file";
                      value = "/home/ors/files/denmark-latest.osm.pbf";
                    }
                    {
                      name = "ors.endpoints.routing.enabled";
                      value = "true";
                    }
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 8082;
                    }
                  ];
                  resources = {
                    requests = {
                      cpu = "2";
                      memory = "6Gi";
                    };
                    limits = {
                      cpu = "6";
                      memory = "8Gi";
                    };
                  };
                  startupProbe = {
                    httpGet = {
                      path = "/ors/v2/health";
                      port = "http";
                    };
                    periodSeconds = 30;
                    timeoutSeconds = 10;
                    failureThreshold = 120;
                  };
                  readinessProbe = {
                    httpGet = {
                      path = "/ors/v2/health";
                      port = "http";
                    };
                    periodSeconds = 20;
                    timeoutSeconds = 10;
                    failureThreshold = 3;
                  };
                  livenessProbe = {
                    httpGet = {
                      path = "/ors/v2/health";
                      port = "http";
                    };
                    periodSeconds = 60;
                    timeoutSeconds = 10;
                    failureThreshold = 3;
                  };
                  volumeMounts = [
                    {
                      name = "data";
                      mountPath = "/home/ors";
                    }
                  ];
                }
              ];
              volumes = [
                {
                  name = "data";
                  persistentVolumeClaim.claimName = "ors-data";
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
          name = "openrouteservice";
          namespace = "openrouteservice";
        };
        spec = {
          selector.app = "openrouteservice";
          ports = [
            {
              name = "http";
              port = 8082;
              targetPort = "http";
            }
          ];
        };
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "openrouteservice";
          namespace = "openrouteservice";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "ors.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "openrouteservice";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [ { hosts = [ "ors.zaza.haahr.me" ]; } ];
        };
      }
    ];
  };
}
