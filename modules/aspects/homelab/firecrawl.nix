{ ... }: {
  flake.modules.nixos.homelab-firecrawl = { config, pkgs, ... }: {
    sops.secrets = {
      firecrawl_bull_auth_key = { };
      firecrawl_postgres_password = { };
    };

    systemd.services.k3s-firecrawl-secrets = {
      description = "Sync Firecrawl secrets into k3s";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = config.sops.secrets.firecrawl_bull_auth_key.path;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.k3s ];
      script = ''
        k3s kubectl create namespace firecrawl --dry-run=client --output yaml \
          | k3s kubectl apply --filename -

        bull_auth_key="$(tr -d '\n' < ${config.sops.secrets.firecrawl_bull_auth_key.path})"
        postgres_password="$(tr -d '\n' < ${config.sops.secrets.firecrawl_postgres_password.path})"

        k3s kubectl --namespace firecrawl create secret generic firecrawl-secret \
          --from-literal=BULL_AUTH_KEY="$bull_auth_key" \
          --from-literal=POSTGRES_PASSWORD="$postgres_password" \
          --from-literal=NUQ_DATABASE_URL="postgresql://postgres:$postgres_password@nuq-postgres:5432/postgres" \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -
      '';
    };

    services.k3s.manifests.firecrawl.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "firecrawl";
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "firecrawl-config";
          namespace = "firecrawl";
        };
        data = {
          HOST = "0.0.0.0";
          REDIS_URL = "redis://redis:6379";
          REDIS_RATE_LIMIT_URL = "redis://redis:6379";
          PLAYWRIGHT_MICROSERVICE_URL = "http://playwright-service:3000";
          USE_DB_AUTHENTICATION = "false";
          SENTRY_ENVIRONMENT = "production";
          ENV = "production";
          LOGGING_LEVEL = "INFO";
          IS_KUBERNETES = "true";
          SEARXNG_ENDPOINT = "http://searxng.searxng.svc.cluster.local/";
        };
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "playwright-service-config";
          namespace = "firecrawl";
        };
        data = {
          PORT = "3000";
          ALLOW_LOCAL_WEBHOOKS = "false";
        };
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "nuq-postgres-data";
          namespace = "firecrawl";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = "10Gi";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "api";
          namespace = "firecrawl";
          labels.app = "firecrawl-api";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "firecrawl-api";
          template = {
            metadata.labels.app = "firecrawl-api";
            spec = {
              terminationGracePeriodSeconds = 180;
              containers = [
                {
                  name = "api";
                  image = "ghcr.io/firecrawl/firecrawl:latest";
                  imagePullPolicy = "Always";
                  command = [ "node" ];
                  args = [
                    "--max-old-space-size=6144"
                    "dist/src/index.js"
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 3002;
                    }
                  ];
                  env = [
                    {
                      name = "FLY_PROCESS_GROUP";
                      value = "app";
                    }
                    {
                      name = "PORT";
                      value = "3002";
                    }
                  ];
                  envFrom = [
                    { configMapRef.name = "firecrawl-config"; }
                    { secretRef.name = "firecrawl-secret"; }
                  ];
                  livenessProbe = {
                    httpGet = {
                      path = "/v0/health/liveness";
                      port = "http";
                    };
                    initialDelaySeconds = 30;
                    periodSeconds = 30;
                    timeoutSeconds = 5;
                    failureThreshold = 3;
                  };
                  readinessProbe = {
                    httpGet = {
                      path = "/v0/health/readiness";
                      port = "http";
                    };
                    initialDelaySeconds = 30;
                    periodSeconds = 30;
                    timeoutSeconds = 5;
                    failureThreshold = 3;
                  };
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
          name = "api";
          namespace = "firecrawl";
        };
        spec = {
          selector.app = "firecrawl-api";
          ports = [
            {
              name = "http";
              port = 3002;
              targetPort = "http";
            }
          ];
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "worker";
          namespace = "firecrawl";
          labels.app = "firecrawl-worker";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "firecrawl-worker";
          template = {
            metadata.labels.app = "firecrawl-worker";
            spec = {
              terminationGracePeriodSeconds = 60;
              containers = [
                {
                  name = "worker";
                  image = "ghcr.io/firecrawl/firecrawl:latest";
                  imagePullPolicy = "Always";
                  command = [ "node" ];
                  args = [
                    "--max-old-space-size=3072"
                    "dist/src/services/queue-worker.js"
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 3005;
                    }
                  ];
                  env = [
                    {
                      name = "FLY_PROCESS_GROUP";
                      value = "worker";
                    }
                    {
                      name = "PORT";
                      value = "3005";
                    }
                  ];
                  envFrom = [
                    { configMapRef.name = "firecrawl-config"; }
                    { secretRef.name = "firecrawl-secret"; }
                  ];
                  livenessProbe = {
                    httpGet = {
                      path = "/liveness";
                      port = "http";
                    };
                    initialDelaySeconds = 5;
                    periodSeconds = 5;
                    timeoutSeconds = 5;
                    failureThreshold = 3;
                  };
                }
              ];
            };
          };
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "nuq-worker";
          namespace = "firecrawl";
          labels.app = "firecrawl-nuq-worker";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "firecrawl-nuq-worker";
          template = {
            metadata.labels.app = "firecrawl-nuq-worker";
            spec = {
              terminationGracePeriodSeconds = 60;
              containers = [
                {
                  name = "nuq-worker";
                  image = "ghcr.io/firecrawl/firecrawl:latest";
                  imagePullPolicy = "Always";
                  command = [ "node" ];
                  args = [
                    "--max-old-space-size=3072"
                    "dist/src/services/worker/nuq-worker.js"
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 3006;
                    }
                  ];
                  env = [
                    {
                      name = "FLY_PROCESS_GROUP";
                      value = "nuq-worker";
                    }
                    {
                      name = "NUQ_WORKER_PORT";
                      value = "3006";
                    }
                  ];
                  envFrom = [
                    { configMapRef.name = "firecrawl-config"; }
                    { secretRef.name = "firecrawl-secret"; }
                  ];
                  livenessProbe = {
                    httpGet = {
                      path = "/health";
                      port = "http";
                    };
                    initialDelaySeconds = 5;
                    periodSeconds = 5;
                    timeoutSeconds = 5;
                    failureThreshold = 3;
                  };
                  readinessProbe = {
                    httpGet = {
                      path = "/health";
                      port = "http";
                    };
                    initialDelaySeconds = 5;
                    periodSeconds = 5;
                    timeoutSeconds = 5;
                    failureThreshold = 3;
                  };
                }
              ];
            };
          };
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "playwright-service";
          namespace = "firecrawl";
          labels.app = "playwright-service";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "playwright-service";
          template = {
            metadata.labels.app = "playwright-service";
            spec.containers = [
              {
                name = "playwright-service";
                image = "ghcr.io/firecrawl/playwright-service:latest";
                imagePullPolicy = "Always";
                ports = [
                  {
                    name = "http";
                    containerPort = 3000;
                  }
                ];
                envFrom = [ { configMapRef.name = "playwright-service-config"; } ];
                livenessProbe = {
                  httpGet = {
                    path = "/health";
                    port = "http";
                  };
                  initialDelaySeconds = 30;
                  periodSeconds = 30;
                  timeoutSeconds = 5;
                  failureThreshold = 3;
                };
              }
            ];
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "playwright-service";
          namespace = "firecrawl";
        };
        spec = {
          selector.app = "playwright-service";
          ports = [
            {
              name = "http";
              port = 3000;
              targetPort = "http";
            }
          ];
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "nuq-postgres";
          namespace = "firecrawl";
          labels.app = "nuq-postgres";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "nuq-postgres";
          template = {
            metadata.labels.app = "nuq-postgres";
            spec = {
              containers = [
                {
                  name = "nuq-postgres";
                  image = "ghcr.io/firecrawl/nuq-postgres:latest";
                  imagePullPolicy = "Always";
                  ports = [
                    {
                      name = "postgres";
                      containerPort = 5432;
                    }
                  ];
                  env = [
                    {
                      name = "POSTGRES_USER";
                      value = "postgres";
                    }
                    {
                      name = "POSTGRES_DB";
                      value = "postgres";
                    }
                    {
                      name = "POSTGRES_PASSWORD";
                      valueFrom.secretKeyRef = {
                        name = "firecrawl-secret";
                        key = "POSTGRES_PASSWORD";
                      };
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "postgres-storage";
                      mountPath = "/var/lib/postgresql/data";
                    }
                  ];
                }
              ];
              volumes = [
                {
                  name = "postgres-storage";
                  persistentVolumeClaim.claimName = "nuq-postgres-data";
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
          name = "nuq-postgres";
          namespace = "firecrawl";
        };
        spec = {
          selector.app = "nuq-postgres";
          ports = [
            {
              name = "postgres";
              port = 5432;
              targetPort = "postgres";
            }
          ];
          type = "ClusterIP";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "redis";
          namespace = "firecrawl";
          labels.app = "redis";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "redis";
          template = {
            metadata.labels.app = "redis";
            spec.containers = [
              {
                name = "redis";
                image = "redis:alpine";
                command = [
                  "/bin/sh"
                  "-c"
                ];
                args = [
                  ''
                    if [ -n "$REDIS_PASSWORD" ]; then
                      exec redis-server --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD"
                    else
                      exec redis-server --bind 0.0.0.0
                    fi
                  ''
                ];
                ports = [
                  {
                    name = "redis";
                    containerPort = 6379;
                  }
                ];
                env = [
                  {
                    name = "REDIS_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "firecrawl-secret";
                      key = "REDIS_PASSWORD";
                      optional = true;
                    };
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
          name = "redis";
          namespace = "firecrawl";
        };
        spec = {
          selector.app = "redis";
          ports = [
            {
              name = "redis";
              port = 6379;
              targetPort = "redis";
            }
          ];
        };
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "firecrawl";
          namespace = "firecrawl";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "firecrawl.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "api";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "firecrawl.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
