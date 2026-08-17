{ hermesHonchoPlugin, ... }: {
  flake.modules.nixos.homelab-hermes-bootstrap =
    { hermesRuntime, ... }:
    {
      _module.args.hermesBootstrapInitContainer = {
        name = "hermes-env";
        image = "busybox:latest";
        command = [ "/var/run/hermes-managed/hermes-bootstrap" ];
        volumeMounts = [
          {
            name = "data";
            mountPath = "/opt/data";
          }
          {
            name = "hermes-cont-init";
            mountPath = "/var/run/hermes-managed";
            readOnly = true;
          }
        ];
        securityContext.runAsUser = 0;
      };

      services.k3s.manifests.hermes-bootstrap.content = {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "hermes-cont-init";
          namespace = "hermes";
        };
        data = {
          "99-clear-honcho-auth" = ''
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
          "hermes-bootstrap" = ''
            #!/bin/sh
            set -eu

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
            ${hermesHonchoPlugin.configYaml}
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
            cp /var/run/hermes-managed/honcho.json /opt/data/honcho.json
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
              sed -i 's|^HONCHO_BASE_URL=.*|HONCHO_BASE_URL=${hermesHonchoPlugin.honchoJson.baseUrl}|' /opt/data/.env
            else
              printf '\nHONCHO_BASE_URL=${hermesHonchoPlugin.honchoJson.baseUrl}\n' >> /opt/data/.env
            fi
            cp /opt/data/.env /opt/data/.hermes/.env
            cp /opt/data/honcho.json /opt/data/.hermes/honcho.json
            rm -f /opt/data/.honcho/config.json
            ln -s /opt/data/honcho.json /opt/data/.honcho/config.json
            awk '
              BEGIN { in_plugins = 0; skip_enabled = 0; wrote_plugins = 0 }
              function enabled_block() {
                print "  enabled:"
                print "    - brainrot-summarizer"
                print "    - ${hermesHonchoPlugin.name}"
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
              in_plugins && $0 ~ /^    - (brainrot-summarizer|${hermesHonchoPlugin.name})$/ { next }
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
                print "  base_url: ${hermesHonchoPlugin.honchoJson.baseUrl}"
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

            sys.path.insert(0, "${hermesRuntime.pythonSitePackages}")

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
            chown -R 1000:100 /opt/data
            chmod -R u+rwX,g+rwX /opt/data
            chmod g+rx /opt/data /opt/data/cache /opt/data/cache/screenshots
          '';
          "honcho.json" = builtins.toJSON hermesHonchoPlugin.honchoJson;
        };
      };
    };
}
