{ hermesHonchoPlugin, ... }: {
  flake.modules.nixos.homelab-hermes-deployment =
    {
      hermesRuntime,
      hermesBootstrapInitContainer,
      hermesSignalCli,
      pkgs,
      ...
    }:
    let
      inherit (hermesRuntime)
        brainrotImageTag
        brainrotPlugin
        mediaToolsImageTag
        pythonSitePackages
        ;
      honchoPlugin = hermesHonchoPlugin;
    in
    {
      services.k3s.manifests.hermes.content = [
        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "hermes";
            namespace = "hermes";
            labels.app = "hermes";
          };
          spec = {
            # The secret-sync service scales up only after local OCI images are imported.
            replicas = 0;
            strategy.type = "Recreate";
            selector.matchLabels.app = "hermes";
            template = {
              metadata.labels.app = "hermes";
              spec = {
                securityContext = {
                  fsGroup = 100;
                  fsGroupChangePolicy = "OnRootMismatch";
                };
                initContainers = [
                  hermesBootstrapInitContainer
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
                        chown -R 1000:100 /hermes-plugins
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
                    image = "hermes-brainrot-plugin:${brainrotImageTag}";
                    imagePullPolicy = "IfNotPresent";
                    command = [ "sh" ];
                    args = [
                      "-c"
                      ''
                        mkdir -p /hermes-plugins /opt/data/.hermes/plugins
                        rm -rf /hermes-plugins/brainrot-summarizer /opt/data/.hermes/plugins/brainrot-summarizer
                        cp -a ${brainrotPlugin} /hermes-plugins/brainrot-summarizer
                        cp -a ${brainrotPlugin} /opt/data/.hermes/plugins/brainrot-summarizer
                        chown -R 1000:100 /hermes-plugins /opt/data/.hermes
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
                    name = "hermes-ssh-key";
                    image = "nousresearch/hermes-agent:latest";
                    command = [ "sh" ];
                    args = [
                      "-c"
                      ''
                        set -eu
                        umask 077
                        mkdir -p /opt/data/.ssh
                        if [ ! -f /opt/data/.ssh/id_ed25519 ]; then
                          ssh-keygen -q -t ed25519 -N "" -C hermes@zaza -f /opt/data/.ssh/id_ed25519
                        fi
                        if [ ! -f /opt/data/.ssh/config ]; then
                          cat > /opt/data/.ssh/config <<'EOF'
                        Host *
                          IdentityFile ~/.ssh/id_ed25519
                          IdentitiesOnly yes
                          StrictHostKeyChecking accept-new
                        EOF
                        fi
                        chmod 700 /opt/data/.ssh
                        chmod 600 /opt/data/.ssh/id_ed25519
                        chmod 600 /opt/data/.ssh/config
                        chmod 644 /opt/data/.ssh/id_ed25519.pub /opt/data/.ssh/known_hosts 2>/dev/null || true
                      ''
                    ];
                    volumeMounts = [
                      {
                        name = "data";
                        mountPath = "/opt/data";
                      }
                    ];
                    securityContext = {
                      runAsUser = 1000;
                      runAsGroup = 100;
                    };
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
                      runAsUser = 1000;
                      runAsGroup = 100;
                    };
                  }
                  {
                    name = "hermes-media-tools";
                    image = "hermes-media-tools:${mediaToolsImageTag}";
                    imagePullPolicy = "IfNotPresent";
                    command = [ "sh" ];
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
                ]
                ++ hermesSignalCli.initContainers;
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
                        value = "1000";
                      }
                      {
                        name = "HERMES_GID";
                        value = "100";
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
                        name = "workspace";
                        mountPath = "/workspace";
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
                        value = "1000";
                      }
                      {
                        name = "HERMES_GID";
                        value = "100";
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
                ]
                ++ hermesSignalCli.containers;
                volumes = [
                  {
                    name = "data";
                    persistentVolumeClaim.claimName = "hermes-data";
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
                    name = "workspace";
                    hostPath = {
                      path = "/home/ph/dev";
                      type = "Directory";
                    };
                  }
                  {
                    name = "dev-shm";
                    emptyDir = {
                      medium = "Memory";
                      sizeLimit = "256Mi";
                    };
                  }
                ]
                ++ hermesSignalCli.volumes;
              };
            };
          };
        }
      ];
    };
}
