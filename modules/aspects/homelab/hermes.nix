{ hermesHonchoPlugin, ... }: {
  flake.modules.nixos.homelab-hermes =
    { config, pkgs, ... }:
    let
      brainrotPlugin = ./hermes/plugins/brainrot-summarizer;
      honchoPlugin = hermesHonchoPlugin;
      honchoPython = pkgs.python313.withPackages (pythonPackages: [
        (pythonPackages.buildPythonPackage {
          pname = "honcho-ai";
          version = "2.1.2";
          pyproject = true;
          src = "${
            pkgs.fetchFromGitHub {
              owner = "plastic-labs";
              repo = "honcho";
              rev = "60a15e664d7298eb790b788e95c6ca2e6bd30c80";
              hash = "sha256-FI9JO436dJD83tmyLTYSWNLSUkeErgGwId3ewI9j9ig=";
            }
          }/sdks/python";
          build-system = [ pythonPackages.setuptools ];
          dependencies = [
            pythonPackages.httpx
            pythonPackages.pydantic
          ];
          doCheck = false;
          pythonImportsCheck = [ "honcho" ];
        })
        pythonPackages.httpx
      ]);
      pythonSitePackages = "${honchoPython}/${pkgs.python313.sitePackages}";
      enabledPlugins = [
        "brainrot-summarizer"
        honchoPlugin.name
      ];
      enabledPluginsAwk = builtins.concatStringsSep "\n" (
        map (plugin: "                        print \"    - ${plugin}\"") enabledPlugins
      );
      honchoJson = pkgs.writeText "hermes-honcho.json" (builtins.toJSON honchoPlugin.honchoJson);
    in
    {
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
          name = "hermes-brainrot-plugin";
          tag = "latest";
          contents = [
            pkgs.busybox
            brainrotPlugin
          ];
          config.Cmd = [ "${pkgs.busybox}/bin/true" ];
        })
        (pkgs.dockerTools.buildLayeredImage {
          name = "hermes-media-tools";
          tag = "latest";
          contents = [
            pkgs.busybox
            pkgs.ffmpeg
            honchoPython
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

          if k3s kubectl --namespace hermes get deployment hermes >/dev/null 2>&1; then
            k3s kubectl --namespace hermes rollout restart deployment/hermes
          fi
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
          apiVersion = "v1";
          kind = "ConfigMap";
          metadata = {
            name = "hermes-cont-init";
            namespace = "hermes";
          };
          data."99-clear-honcho-auth" = ''
            #!/bin/sh
            set -eu

            for file in /opt/data/.env /opt/data/.hermes/.env; do
              if [ -f "$file" ]; then
                sed -i \
                  -e '/^HONCHO_API_KEY=/d' \
                  -e '/^HONCHO_TOKEN=/d' \
                  -e '/^HONCHO_BEARER_TOKEN=/d' \
                  -e '/^export HONCHO_API_KEY=/d' \
                  -e '/^export HONCHO_TOKEN=/d' \
                  -e '/^export HONCHO_BEARER_TOKEN=/d' \
                  "$file"
              fi
            done

            cp /var/run/hermes-managed/honcho.json /opt/data/honcho.json
            cp /opt/data/honcho.json /opt/data/.hermes/honcho.json
            rm -f /opt/data/.honcho/config.json
            ln -s /opt/data/honcho.json /opt/data/.honcho/config.json
          '';
          data."honcho.json" = builtins.toJSON honchoPlugin.honchoJson;
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
              spec = {
                securityContext = {
                  fsGroup = 10000;
                  fsGroupChangePolicy = "OnRootMismatch";
                };
                initContainers = [
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
                                            mkdir -p /opt/data/cache/screenshots /opt/data/hermes-patches /opt/data/.hermes/plugins /opt/data/.honcho
                                            cat > /tmp/hermes-managed-config.yaml <<'YAML'
                                            model:
                                              provider: custom
                                              default: qwen3.6-35b-a3b
                                              base_url: http://100.75.6.21:8080/v1
                                            custom_providers:
                                              - name: nika-llamacpp
                                                base_url: http://100.75.6.21:8080/v1
                                                model: qwen3.6-35b-a3b
                                            mcp_servers:
                                              firecrawl:
                                                command: npx
                                                args:
                                                  - -y
                                                  - firecrawl-mcp
                                                env:
                                                  FIRECRAWL_API_URL: http://api.firecrawl.svc.cluster.local:3002
                                            ${honchoPlugin.configYaml}
                                            YAML
                                            if [ -f /opt/data/config.yaml ]; then
                                              awk '
                                                BEGIN { skipping = 0 }
                                                /^(custom_providers|mcp_servers|memory|model):[[:space:]]*$/ { skipping = 1; next }
                                                skipping && /^[[:alnum:]_]+:[[:space:]]*/ { skipping = 0 }
                                                !skipping { print }
                                              ' /opt/data/config.yaml > /opt/data/config.yaml.tmp
                                              cat /tmp/hermes-managed-config.yaml >> /opt/data/config.yaml.tmp
                                              mv /opt/data/config.yaml.tmp /opt/data/config.yaml
                                            else
                                              cp /tmp/hermes-managed-config.yaml /opt/data/config.yaml
                                            fi
                                            cp ${honchoJson} /opt/data/honcho.json
                                            for file in /opt/data/.env /opt/data/.hermes/.env; do
                                              if [ -f "$file" ]; then
                                                sed -i \
                                                  -e '/^HONCHO_API_KEY=/d' \
                                                  -e '/^HONCHO_TOKEN=/d' \
                                                  -e '/^HONCHO_BEARER_TOKEN=/d' \
                                                  -e '/^export HONCHO_API_KEY=/d' \
                                                  -e '/^export HONCHO_TOKEN=/d' \
                                                  -e '/^export HONCHO_BEARER_TOKEN=/d' \
                                                  "$file"
                                              fi
                                            done
                                            if grep -q '^HONCHO_BASE_URL=' /opt/data/.env; then
                                              sed -i 's|^HONCHO_BASE_URL=.*|HONCHO_BASE_URL=${honchoPlugin.honchoJson.baseUrl}|' /opt/data/.env
                                            else
                                              printf '\nHONCHO_BASE_URL=${honchoPlugin.honchoJson.baseUrl}\n' >> /opt/data/.env
                                            fi
                                            cp /opt/data/.env /opt/data/.hermes/.env
                                            cp /opt/data/honcho.json /opt/data/.hermes/honcho.json
                                            rm -f /opt/data/.honcho/config.json
                                            ln -s /opt/data/honcho.json /opt/data/.honcho/config.json
                                            awk '
                                              BEGIN { in_plugins = 0; skip_enabled = 0; wrote_plugins = 0 }
                                              function enabled_block() {
                                                print "  enabled:"
                        ${enabledPluginsAwk}
                                              }
                                              /^(custom_providers|memory|model|honcho):[[:space:]]*$/ {
                                                skip_section = 1
                                                next
                                              }
                                              skip_section && /^[[:alnum:]_]+:[[:space:]]*/ {
                                                skip_section = 0
                                              }
                                              skip_section { next }
                                              /^[^[:space:]].*:/ {
                                                if (in_plugins && !wrote_plugins) {
                                                  enabled_block()
                                                  wrote_plugins = 1
                                                }
                                                if ($0 == "plugins:") {
                                                  print
                                                  enabled_block()
                                                  in_plugins = 1
                                                  skip_enabled = 0
                                                  wrote_plugins = 1
                                                  next
                                                }
                                                in_plugins = 0
                                                skip_enabled = 0
                                                print
                                                next
                                              }
                                              in_plugins && $0 ~ /^  enabled:/ {
                                                skip_enabled = 1
                                                next
                                              }
                                              in_plugins && skip_enabled && $0 ~ /^    - / { next }
                                              in_plugins && skip_enabled { skip_enabled = 0 }
                                              in_plugins && $0 ~ /^    - (brainrot-summarizer|${honchoPlugin.name})$/ { next }
                                              { print }
                                              END {
                                                if (!wrote_plugins) {
                                                  print ""
                                                  print "plugins:"
                                                  enabled_block()
                                                }
                                                print ""
                                                print "model:"
                                                print "  provider: custom"
                                                print "  default: qwen3.6-35b-a3b"
                                                print "  base_url: http://100.75.6.21:8080/v1"
                                                print "custom_providers:"
                                                print "  - name: nika-llamacpp"
                                                print "    base_url: http://100.75.6.21:8080/v1"
                                                print "    model: qwen3.6-35b-a3b"
                                                print ""
                                                print "honcho:"
                                                print "  base_url: ${honchoPlugin.honchoJson.baseUrl}"
                                                print "memory:"
                                                print "  provider: honcho"
                                              }
                                            ' /opt/data/config.yaml > /opt/data/config.yaml.tmp
                                            mv /opt/data/config.yaml.tmp /opt/data/config.yaml
                                            cp /opt/data/config.yaml /opt/data/.hermes/config.yaml
                                            cat > /opt/data/hermes-patches/sitecustomize.py <<'PY'
                                            import sys
                                            import re
                                            from urllib.parse import urlsplit, urlunsplit

                                            sys.path.insert(0, "${pythonSitePackages}")

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
                    name = "hermes-bundled-plugins";
                    image = "nousresearch/hermes-agent:latest";
                    command = [ "sh" ];
                    args = [
                      "-c"
                      ''
                        mkdir -p /hermes-plugins
                        if [ -d /opt/hermes/plugins ]; then
                          cp -a /opt/hermes/plugins/. /hermes-plugins/
                        fi
                        chown -R 10000:10000 /hermes-plugins
                        chmod -R u+rwX,g+rwX /hermes-plugins
                      ''
                    ];
                    volumeMounts = [
                      {
                        name = "hermes-plugins";
                        mountPath = "/hermes-plugins";
                      }
                    ];
                    securityContext.runAsUser = 0;
                  }
                  {
                    name = "hermes-brainrot-plugin";
                    image = "hermes-brainrot-plugin:latest";
                    imagePullPolicy = "IfNotPresent";
                    command = [ "${pkgs.busybox}/bin/sh" ];
                    args = [
                      "-c"
                      ''
                        mkdir -p /hermes-plugins /opt/data/.hermes/plugins
                        rm -rf /hermes-plugins/brainrot-summarizer /opt/data/.hermes/plugins/brainrot-summarizer
                        cp -a ${brainrotPlugin} /hermes-plugins/brainrot-summarizer
                        cp -a ${brainrotPlugin} /opt/data/.hermes/plugins/brainrot-summarizer
                        chown -R 10000:10000 /hermes-plugins /opt/data/.hermes
                        chmod -R u+rwX,g+rwX /hermes-plugins /opt/data/.hermes
                      ''
                    ];
                    volumeMounts = [
                      {
                        name = "data";
                        mountPath = "/opt/data";
                      }
                      {
                        name = "hermes-plugins";
                        mountPath = "/hermes-plugins";
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
                containers = [
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
                        name = "HERMES_HOME";
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
                        name = "HONCHO_BASE_URL";
                        value = honchoPlugin.honchoJson.baseUrl;
                      }
                      {
                        name = "HONCHO_URL";
                        value = honchoPlugin.honchoJson.baseUrl;
                      }
                      {
                        name = "HONCHO_API_KEY";
                        value = "";
                      }
                      {
                        name = "HONCHO_TOKEN";
                        value = "";
                      }
                      {
                        name = "HONCHO_BEARER_TOKEN";
                        value = "";
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
                        value = "${pythonSitePackages}:/opt/data/hermes-patches";
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
                        name = "hermes-plugins";
                        mountPath = "/opt/hermes/plugins";
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
                      {
                        name = "hermes-cont-init";
                        mountPath = "/etc/cont-init.d/99-clear-honcho-auth";
                        subPath = "99-clear-honcho-auth";
                        readOnly = true;
                      }
                      {
                        name = "hermes-cont-init";
                        mountPath = "/var/run/hermes-managed";
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
                        name = "HOME";
                        value = "/opt/data";
                      }
                      {
                        name = "HERMES_HOME";
                        value = "/opt/data";
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
                      {
                        name = "hermes-cont-init";
                        mountPath = "/etc/cont-init.d/99-clear-honcho-auth";
                        subPath = "99-clear-honcho-auth";
                        readOnly = true;
                      }
                      {
                        name = "hermes-cont-init";
                        mountPath = "/var/run/hermes-managed";
                        readOnly = true;
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
                volumes = [
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
                    name = "hermes-plugins";
                    emptyDir = { };
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
                    name = "hermes-cont-init";
                    configMap = {
                      name = "hermes-cont-init";
                      defaultMode = 493;
                    };
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
