{ ... }: {
  flake.modules.nixos.homelab-honcho = { config, pkgs, ... }:
    let
      honchoImage = "ghcr.io/plastic-labs/honcho:v3.0.11";
    in
    {
    sops.secrets = {
      honcho_auth_jwt_secret = { };
      honcho_postgres_password = { };
      hermes_api_server_key = { };
    };

    systemd.services.k3s-honcho-secrets = {
      description = "Sync Honcho secrets into k3s";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = config.sops.secrets.honcho_postgres_password.path;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.k3s ];
      script = ''
        k3s kubectl create namespace honcho --dry-run=client --output yaml \
          | k3s kubectl apply --filename -

        postgres_password="$(tr -d '\n' < ${config.sops.secrets.honcho_postgres_password.path})"

        k3s kubectl --namespace honcho create secret generic honcho-postgres \
          --from-literal=POSTGRES_PASSWORD="$postgres_password" \
          --from-literal=DB_CONNECTION_URI="postgresql+psycopg://postgres:$postgres_password@postgres:5432/postgres" \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -

        auth_jwt_secret="$(tr -d '\n' < ${config.sops.secrets.honcho_auth_jwt_secret.path})"
        llm_openai_api_key="$(tr -d '\n' < ${config.sops.secrets.hermes_api_server_key.path})"

        k3s kubectl --namespace honcho create secret generic honcho-app \
          --from-literal=AUTH_JWT_SECRET="$auth_jwt_secret" \
          --from-literal=LLM_OPENAI_API_KEY="$llm_openai_api_key" \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -

        for deployment in api deriver; do
          if k3s kubectl --namespace honcho get deployment "$deployment" >/dev/null 2>&1; then
            k3s kubectl --namespace honcho rollout restart "deployment/$deployment"
          fi
        done
      '';
    };

    services.k3s.manifests.honcho.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "honcho";
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "honcho-config";
          namespace = "honcho";
        };
        data = {
          AUTH_USE_AUTH = "false";
          CACHE_ENABLED = "true";
          CACHE_URL = "redis://redis:6379/0?suppress=true";
          CORS_ORIGINS = ''["https://honcho.zaza.haahr.me"]'';
          DERIVER_ENABLED = "true";
          DERIVER_FLUSH_ENABLED = "false";
          DERIVER_POLLING_BACKOFF_MULTIPLIER = "3";
          DERIVER_POLLING_SLEEP_INTERVAL_SECONDS = "10";
          DERIVER_POLLING_SLEEP_MAX_INTERVAL_SECONDS = "120";
          DERIVER_REPRESENTATION_BATCH_MAX_AGE_SECONDS = "30";
          DERIVER_REPRESENTATION_BATCH_MAX_TOKENS = "512";
          DERIVER_MODEL_CONFIG__MODEL = "hermes-agent";
          DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          DERIVER_MODEL_CONFIG__TRANSPORT = "openai";
          DERIVER_WORKERS = "1";
          DIALECTIC_LEVELS__high__MODEL_CONFIG__MODEL = "hermes-agent";
          DIALECTIC_LEVELS__high__MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          DIALECTIC_LEVELS__high__MODEL_CONFIG__TRANSPORT = "openai";
          DIALECTIC_LEVELS__low__MODEL_CONFIG__MODEL = "hermes-agent";
          DIALECTIC_LEVELS__low__MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          DIALECTIC_LEVELS__low__MODEL_CONFIG__TRANSPORT = "openai";
          DIALECTIC_LEVELS__max__MODEL_CONFIG__MODEL = "hermes-agent";
          DIALECTIC_LEVELS__max__MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          DIALECTIC_LEVELS__max__MODEL_CONFIG__TRANSPORT = "openai";
          DIALECTIC_LEVELS__medium__MODEL_CONFIG__MODEL = "hermes-agent";
          DIALECTIC_LEVELS__medium__MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          DIALECTIC_LEVELS__medium__MODEL_CONFIG__TRANSPORT = "openai";
          DIALECTIC_LEVELS__minimal__MODEL_CONFIG__MODEL = "hermes-agent";
          DIALECTIC_LEVELS__minimal__MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          DIALECTIC_LEVELS__minimal__MODEL_CONFIG__TRANSPORT = "openai";
          DREAM_DEDUCTION_MODEL_CONFIG__MODEL = "hermes-agent";
          DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          DREAM_DEDUCTION_MODEL_CONFIG__TRANSPORT = "openai";
          DREAM_INDUCTION_MODEL_CONFIG__MODEL = "hermes-agent";
          DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          DREAM_INDUCTION_MODEL_CONFIG__TRANSPORT = "openai";
          EMBEDDING_MAX_CONCURRENT_EMBEDDINGS = "1";
          EMBEDDING_MODEL_CONFIG__MODEL = "nomic-embed-text-v1.5";
          EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL = "http://llamacpp-embeddings.llamacpp.svc.cluster.local:8080/v1";
          EMBEDDING_MODEL_CONFIG__TRANSPORT = "openai";
          EMBEDDING_VECTOR_DIMENSIONS = "768";
          LOG_LEVEL = "INFO";
          NAMESPACE = "honcho";
          SUMMARY_MODEL_CONFIG__MODEL = "hermes-agent";
          SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL = "http://hermes-api-server.hermes.svc.cluster.local:8642/v1";
          SUMMARY_MODEL_CONFIG__TRANSPORT = "openai";
          SENTRY_ENABLED = "false";
          VECTOR_STORE_TYPE = "pgvector";
        };
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "postgres-init";
          namespace = "honcho";
        };
        data."init.sql" = ''
          CREATE EXTENSION IF NOT EXISTS vector;
        '';
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "postgres-data";
          namespace = "honcho";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = "20Gi";
        };
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "redis-data";
          namespace = "honcho";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = "2Gi";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "postgres";
          namespace = "honcho";
          labels.app = "honcho-postgres";
        };
        spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "honcho-postgres";
          template = {
            metadata.labels.app = "honcho-postgres";
            spec.containers = [
              {
                name = "postgres";
                image = "pgvector/pgvector:pg15";
                args = [
                  "postgres"
                  "-c"
                  "max_connections=200"
                ];
                ports = [
                  {
                    name = "postgres";
                    containerPort = 5432;
                  }
                ];
                env = [
                  {
                    name = "POSTGRES_DB";
                    value = "postgres";
                  }
                  {
                    name = "POSTGRES_USER";
                    value = "postgres";
                  }
                  {
                    name = "POSTGRES_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "honcho-postgres";
                      key = "POSTGRES_PASSWORD";
                    };
                  }
                  {
                    name = "PGDATA";
                    value = "/var/lib/postgresql/data/pgdata";
                  }
                ];
                readinessProbe = {
                  exec.command = [
                    "pg_isready"
                    "-U"
                    "postgres"
                    "-d"
                    "postgres"
                  ];
                  initialDelaySeconds = 10;
                  periodSeconds = 10;
                  timeoutSeconds = 5;
                };
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/var/lib/postgresql/data";
                  }
                  {
                    name = "init";
                    mountPath = "/docker-entrypoint-initdb.d/init.sql";
                    subPath = "init.sql";
                    readOnly = true;
                  }
                ];
              }
            ];
            spec.volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "postgres-data";
              }
              {
                name = "init";
                configMap.name = "postgres-init";
              }
            ];
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "postgres";
          namespace = "honcho";
        };
        spec = {
          selector.app = "honcho-postgres";
          ports = [
            {
              name = "postgres";
              port = 5432;
              targetPort = "postgres";
            }
          ];
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "redis";
          namespace = "honcho";
          labels.app = "honcho-redis";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "honcho-redis";
          template = {
            metadata.labels.app = "honcho-redis";
            spec.containers = [
              {
                name = "redis";
                image = "redis:8.2";
                ports = [
                  {
                    name = "redis";
                    containerPort = 6379;
                  }
                ];
                readinessProbe = {
                  exec.command = [
                    "redis-cli"
                    "ping"
                  ];
                  initialDelaySeconds = 5;
                  periodSeconds = 10;
                  timeoutSeconds = 5;
                };
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/data";
                  }
                ];
              }
            ];
            spec.volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "redis-data";
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
          namespace = "honcho";
        };
        spec = {
          selector.app = "honcho-redis";
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
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "api";
          namespace = "honcho";
          labels.app = "honcho-api";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "honcho-api";
          template = {
            metadata.labels.app = "honcho-api";
            spec.containers = [
              {
                name = "api";
                image = honchoImage;
                imagePullPolicy = "IfNotPresent";
                command = [ "sh" ];
                args = [ "docker/entrypoint.sh" ];
                ports = [
                  {
                    name = "http";
                    containerPort = 8000;
                  }
                ];
                envFrom = [
                  { configMapRef.name = "honcho-config"; }
                  { secretRef.name = "honcho-app"; }
                  { secretRef.name = "honcho-postgres"; }
                ];
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
                startupProbe = {
                  httpGet = {
                    path = "/health";
                    port = "http";
                  };
                  periodSeconds = 10;
                  timeoutSeconds = 5;
                  failureThreshold = 60;
                };
                readinessProbe = {
                  httpGet = {
                    path = "/health";
                    port = "http";
                  };
                  initialDelaySeconds = 10;
                  periodSeconds = 10;
                  timeoutSeconds = 5;
                  failureThreshold = 6;
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
          name = "api";
          namespace = "honcho";
        };
        spec = {
          type = "ClusterIP";
          selector.app = "honcho-api";
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
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "deriver";
          namespace = "honcho";
          labels.app = "honcho-deriver";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "honcho-deriver";
          template = {
            metadata.labels.app = "honcho-deriver";
            spec.containers = [
              {
                name = "deriver";
                image = honchoImage;
                imagePullPolicy = "IfNotPresent";
                command = [ "/app/.venv/bin/python" ];
                args = [
                  "-m"
                  "src.deriver"
                ];
                envFrom = [
                  { configMapRef.name = "honcho-config"; }
                  { secretRef.name = "honcho-app"; }
                  { secretRef.name = "honcho-postgres"; }
                ];
              }
            ];
          };
        };
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "honcho";
          namespace = "honcho";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "honcho.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "api";
                    port.number = 80;
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "honcho.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
