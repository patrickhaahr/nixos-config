{ ... }: {
  flake.modules.nixos.homelab-hermes = { config, pkgs, ... }: {
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8642 ];

    sops.secrets = {
      hermes_dashboard_basic_auth_username = { };
      hermes_dashboard_basic_auth_password = { };
      hermes_dashboard_basic_auth_secret = { };
      hermes_api_server_key = { };
      hermes_signal_account = { };
    };

    services.k3s.images = [
      (pkgs.dockerTools.buildLayeredImage {
        name = "hermes-media-tools";
        tag = "latest";
        contents = [
          pkgs.busybox
          pkgs.ffmpeg
          pkgs.yt-dlp
        ];
        config.Cmd = [ "${pkgs.busybox}/bin/true" ];
      })
    ];

    systemd.services.k3s-hermes-secrets = {
      description = "Sync Hermes secrets into k3s";
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

        k3s kubectl --namespace hermes create secret generic hermes-signal \
          --from-file=SIGNAL_ACCOUNT=${config.sops.secrets.hermes_signal_account.path} \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -

        k3s kubectl --namespace hermes create secret generic hermes-api-server \
          --from-file=API_SERVER_KEY=${config.sops.secrets.hermes_api_server_key.path} \
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
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "signal-cli-data";
          namespace = "hermes";
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
          name = "hermes";
          namespace = "hermes";
          labels.app = "hermes";
        };
        spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "hermes";
          template = {
            metadata.labels.app = "hermes";
            spec.securityContext = {
              fsGroup = 10000;
              fsGroupChangePolicy = "OnRootMismatch";
            };
            spec.initContainers = [
              {
                name = "hermes-env";
                image = "busybox:latest";
                command = [ "sh" ];
                args = [
                  "-c"
                  ''
                    touch /opt/data/.env
                    if grep -q '^SEARXNG_URL=' /opt/data/.env; then
                      sed -i 's|^SEARXNG_URL=.*|SEARXNG_URL=http://searxng.searxng.svc.cluster.local/|' /opt/data/.env
                    else
                      printf '\nSEARXNG_URL=http://searxng.searxng.svc.cluster.local/\n' >> /opt/data/.env
                    fi
                    mkdir -p /opt/data/cache/screenshots /opt/data/hermes-patches
                    cat > /tmp/hermes-firecrawl-mcp.yaml <<'YAML'
                    mcp_servers:
                      firecrawl:
                        command: npx
                        args:
                          - -y
                          - firecrawl-mcp
                        env:
                          FIRECRAWL_API_URL: http://api.firecrawl.svc.cluster.local:3002
                    YAML
                    if [ -f /opt/data/config.yaml ]; then
                      awk '
                        BEGIN { skipping = 0 }
                        /^mcp_servers:[[:space:]]*$/ { skipping = 1; next }
                        skipping && /^[[:alnum:]_]+:[[:space:]]*/ { skipping = 0 }
                        !skipping { print }
                      ' /opt/data/config.yaml > /opt/data/config.yaml.tmp
                      cat /tmp/hermes-firecrawl-mcp.yaml >> /opt/data/config.yaml.tmp
                      mv /opt/data/config.yaml.tmp /opt/data/config.yaml
                    else
                      cp /tmp/hermes-firecrawl-mcp.yaml /opt/data/config.yaml
                    fi
                    cat > /opt/data/hermes-patches/sitecustomize.py <<'PY'
                    import re
                    from urllib.parse import urlsplit, urlunsplit

                    import httpx

                    _original_async_get = httpx.AsyncClient.get
                    _wikimedia_thumb_re = re.compile(r"^/wikipedia/commons/thumb/([^/]+)/([^/]+)/(.+)/[^/]+px-\3$")


                    def _wikimedia_original_url(url: str) -> str | None:
                        parts = urlsplit(url)
                        if parts.netloc != "upload.wikimedia.org":
                            return None

                        match = _wikimedia_thumb_re.match(parts.path)
                        if not match:
                            return None

                        original_path = f"/wikipedia/commons/{match.group(1)}/{match.group(2)}/{match.group(3)}"
                        return urlunsplit((parts.scheme, parts.netloc, original_path, "", ""))


                    async def _get_with_wikimedia_original_fallback(self, url, *args, **kwargs):
                        response = await _original_async_get(self, url, *args, **kwargs)
                        if response.status_code != 400:
                            return response

                        original_url = _wikimedia_original_url(str(response.request.url))
                        if original_url is None:
                            return response

                        if "Use thumbnail sizes" not in response.text[:200]:
                            return response

                        return await _original_async_get(self, original_url, *args, **kwargs)


                    httpx.AsyncClient.get = _get_with_wikimedia_original_fallback
                    PY
                    touch /opt/data/SOUL.md
                    chown -R 10000:10000 /opt/data
                    chmod -R u+rwX,g+rwX /opt/data
                    chmod g+rx /opt/data /opt/data/cache /opt/data/cache/screenshots
                  ''
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/opt/data";
                  }
                ];
                securityContext.runAsUser = 0;
              }
              {
                name = "hermes-local-stt-model";
                image = "nousresearch/hermes-agent:latest";
                command = [ "/opt/hermes/.venv/bin/python" ];
                args = [
                  "-c"
                  ''
                    import sys
                    sys.path.insert(0, "/opt/data/lazy-packages")
                    from faster_whisper import WhisperModel
                    WhisperModel("base", device="cpu", compute_type="int8")
                  ''
                ];
                env = [
                  {
                    name = "HF_HOME";
                    value = "/opt/data/huggingface";
                  }
                  {
                    name = "HF_HUB_CACHE";
                    value = "/opt/data/huggingface/hub";
                  }
                  {
                    name = "XDG_CACHE_HOME";
                    value = "/opt/data/cache";
                  }
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/opt/data";
                  }
                ];
                securityContext = {
                  runAsUser = 10000;
                  runAsGroup = 10000;
                };
              }
              {
                name = "signal-cli-data-permissions";
                image = "registry.gitlab.com/packaging/signal-cli/signal-cli-native:latest";
                command = [ "chown" ];
                args = [
                  "-R"
                  "signal-cli:signal-cli"
                  "/var/lib/signal-cli"
                ];
                securityContext.runAsUser = 0;
                volumeMounts = [
                  {
                    name = "signal-cli-data";
                    mountPath = "/var/lib/signal-cli";
                  }
                ];
              }
              {
                name = "hermes-media-tools";
                image = "hermes-media-tools:latest";
                imagePullPolicy = "IfNotPresent";
                command = [ "${pkgs.busybox}/bin/sh" ];
                args = [
                  "-c"
                  ''
                    mkdir -p /media-tools/bin /media-tools/nix
                    cp -a /nix/store /media-tools/nix/
                    cat > /media-tools/bin/yt-dlp <<'SH'
                    #!/bin/sh
                    unset PYTHONPATH
                    exec ${pkgs.yt-dlp}/bin/yt-dlp "$@"
                    SH
                    chmod +x /media-tools/bin/yt-dlp
                    ln -sf ${pkgs.ffmpeg}/bin/ffmpeg /media-tools/bin/ffmpeg
                    ln -sf ${pkgs.ffmpeg}/bin/ffprobe /media-tools/bin/ffprobe
                  ''
                ];
                volumeMounts = [
                  {
                    name = "media-tools-bin";
                    mountPath = "/media-tools/bin";
                  }
                  {
                    name = "media-tools-store";
                    mountPath = "/media-tools/nix";
                  }
                ];
              }
            ];
            spec.containers = [
              {
                name = "gateway";
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
                  {
                    name = "HOME";
                    value = "/opt/data";
                  }
                  {
                    name = "PATH";
                    value = "/media-tools/bin:/opt/hermes/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
                  }
                  {
                    name = "SIGNAL_HTTP_URL";
                    value = "http://127.0.0.1:8080";
                  }
                  {
                    name = "SEARXNG_URL";
                    value = "http://searxng.searxng.svc.cluster.local/";
                  }
                  {
                    name = "HF_HOME";
                    value = "/opt/data/huggingface";
                  }
                  {
                    name = "HF_HUB_CACHE";
                    value = "/opt/data/huggingface/hub";
                  }
                  {
                    name = "XDG_CACHE_HOME";
                    value = "/opt/data/cache";
                  }
                  {
                    name = "PYTHONPATH";
                    value = "/opt/data/hermes-patches";
                  }
                  {
                    name = "AGENT_BROWSER_ARGS";
                    value = "--no-sandbox,--disable-dev-shm-usage";
                  }
                  {
                    name = "AGENT_BROWSER_SOCKET_DIR";
                    value = "/tmp/browser-sockets";
                  }
                  {
                    name = "BROWSER_INACTIVITY_TIMEOUT";
                    value = "300";
                  }
                  {
                    name = "TERMINAL_ENV";
                    value = "local";
                  }
                  {
                    name = "HERMES_MEDIA_ALLOW_DIRS";
                    value = "/tmp:/opt/data/cache/screenshots";
                  }
                  {
                    name = "SIGNAL_ACCOUNT";
                    valueFrom.secretKeyRef = {
                      name = "hermes-signal";
                      key = "SIGNAL_ACCOUNT";
                    };
                  }
                  {
                    name = "SIGNAL_ALLOWED_USERS";
                    valueFrom.secretKeyRef = {
                      name = "hermes-signal";
                      key = "SIGNAL_ACCOUNT";
                    };
                  }
                  {
                    name = "API_SERVER_ENABLED";
                    value = "true";
                  }
                  {
                    name = "API_SERVER_HOST";
                    value = "0.0.0.0";
                  }
                  {
                    name = "API_SERVER_PORT";
                    value = "8642";
                  }
                  {
                    name = "API_SERVER_KEY";
                    valueFrom.secretKeyRef = {
                      name = "hermes-api-server";
                      key = "API_SERVER_KEY";
                    };
                  }
                ];
                ports = [
                  {
                    name = "api-server";
                    containerPort = 8642;
                  }
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/opt/data";
                  }
                  {
                    name = "browser-sockets";
                    mountPath = "/tmp/browser-sockets";
                  }
                  {
                    name = "dev-shm";
                    mountPath = "/dev/shm";
                  }
                  {
                    name = "shared-tmp";
                    mountPath = "/tmp";
                  }
                  {
                    name = "media-tools-bin";
                    mountPath = "/media-tools/bin";
                    readOnly = true;
                  }
                  {
                    name = "media-tools-store";
                    mountPath = "/nix";
                    readOnly = true;
                  }
                ];
              }
              {
                name = "dashboard";
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
              {
                name = "signal-cli";
                image = "registry.gitlab.com/packaging/signal-cli/signal-cli-native:latest";
                args = [
                  "daemon"
                  "--http"
                  "127.0.0.1:8080"
                ];
                ports = [
                  {
                    name = "signal-cli";
                    containerPort = 8080;
                  }
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/opt/data";
                  }
                  {
                    name = "signal-cli-data";
                    mountPath = "/var/lib/signal-cli";
                  }
                  {
                    name = "shared-tmp";
                    mountPath = "/tmp";
                  }
                ];
              }
              {
                name = "screenshot-permissions";
                image = "busybox:latest";
                command = [ "sh" ];
                args = [
                  "-c"
                  ''
                    while true; do
                      chmod -R g+rX /opt/data 2>/dev/null || true
                      chmod -R g+rX /tmp 2>/dev/null || true
                      sleep 1
                    done
                  ''
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/opt/data";
                  }
                  {
                    name = "shared-tmp";
                    mountPath = "/tmp";
                  }
                ];
                securityContext.runAsUser = 0;
              }
            ];
            spec.volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "hermes-data";
              }
              {
                name = "signal-cli-data";
                persistentVolumeClaim.claimName = "signal-cli-data";
              }
              {
                name = "shared-tmp";
                emptyDir.medium = "Memory";
              }
              {
                name = "browser-sockets";
                emptyDir = { };
              }
              {
                name = "media-tools-bin";
                emptyDir = { };
              }
              {
                name = "media-tools-store";
                emptyDir = { };
              }
              {
                name = "dev-shm";
                emptyDir = {
                  medium = "Memory";
                  sizeLimit = "256Mi";
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
          name = "hermes-dashboard";
          namespace = "hermes";
        };
        spec = {
          selector.app = "hermes";
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
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "hermes-api-server";
          namespace = "hermes";
        };
        spec = {
          type = "LoadBalancer";
          selector.app = "hermes";
          ports = [
            {
              name = "http";
              port = 8642;
              targetPort = "api-server";
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
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "hermes-api-server";
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
              host = "hermes-api.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "hermes-api-server";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "hermes-api.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
