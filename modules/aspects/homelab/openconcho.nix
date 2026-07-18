_: {
  flake.modules.nixos.homelab-openconcho = { config, pkgs, ... }: {
    sops.secrets.honcho_auth_jwt_secret = { };

    systemd.services.k3s-openconcho-secrets = {
      description = "Sync OpenConcho secrets into k3s";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = config.sops.secrets.honcho_auth_jwt_secret.path;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [
        pkgs.k3s
        pkgs.nodejs
      ];
      script = ''
        k3s kubectl create namespace openconcho --dry-run=client --output yaml \
          | k3s kubectl apply --filename -

        export HONCHO_AUTH_JWT_SECRET="$(tr -d '\n' < ${config.sops.secrets.honcho_auth_jwt_secret.path})"
        honcho_api_key="$(node <<'EOF'
        const { createHmac } = require("node:crypto");

        function base64urlJson(value) {
          return Buffer.from(JSON.stringify(value)).toString("base64url");
        }

        const header = base64urlJson({ alg: "HS256", typ: "JWT" });
        const payload = base64urlJson({ t: "", ad: true });
        const signingInput = header + "." + payload;
        const signature = createHmac("sha256", process.env.HONCHO_AUTH_JWT_SECRET)
          .update(signingInput)
          .digest("base64url");
        console.log(signingInput + "." + signature);
        EOF
        )"

        k3s kubectl --namespace openconcho create secret generic openconcho-honcho \
          --from-literal=API_KEY="$honcho_api_key" \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -
      '';
    };

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
              initContainers = [
                {
                  name = "openconcho-config";
                  image = "busybox:latest";
                  command = [ "sh" ];
                  args = [
                    "-c"
                    ''
                      cat > /config/50-openconcho-honcho-config.sh <<'SCRIPT'
                      #!/bin/sh
                      set -eu

                      honcho_api_key="$(tr -d '\n' < /var/run/secrets/honcho/API_KEY)"
                      cat > /usr/share/nginx/html/config.js <<EOF
                      window.__OPENCONCHO_DEFAULT_HONCHO_URL__ = "https://honcho.zaza.haahr.me";
                      try {
                        localStorage.setItem("openconcho:instances", JSON.stringify({
                          instances: [
                            {
                              id: "zaza-honcho",
                              name: "Zaza Honcho",
                              baseUrl: "https://honcho.zaza.haahr.me",
                              token: "$honcho_api_key",
                            },
                          ],
                          activeId: "zaza-honcho",
                        }));
                      } catch (_) {}
                      EOF
                      SCRIPT
                      chmod 0755 /config/50-openconcho-honcho-config.sh
                    ''
                  ];
                  volumeMounts = [
                    {
                      name = "openconcho-config";
                      mountPath = "/config";
                    }
                    {
                      name = "honcho-api-key";
                      mountPath = "/var/run/secrets/honcho";
                      readOnly = true;
                    }
                  ];
                  securityContext = {
                    allowPrivilegeEscalation = false;
                    capabilities.drop = [ "ALL" ];
                  };
                }
              ];
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
                  volumeMounts = [
                    {
                      name = "openconcho-config";
                      mountPath = "/docker-entrypoint.d/50-openconcho-honcho-config.sh";
                      subPath = "50-openconcho-honcho-config.sh";
                    }
                    {
                      name = "honcho-api-key";
                      mountPath = "/var/run/secrets/honcho";
                      readOnly = true;
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
              volumes = [
                {
                  name = "openconcho-config";
                  emptyDir = { };
                }
                {
                  name = "honcho-api-key";
                  secret.secretName = "openconcho-honcho";
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
