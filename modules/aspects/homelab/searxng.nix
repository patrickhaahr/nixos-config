_: {
  flake.modules.nixos.homelab-searxng = { config, pkgs, ... }: {
    sops.secrets.searxng_secret = { };

    systemd.services.k3s-searxng-secrets = {
      description = "Sync SearXNG secrets into k3s";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = config.sops.secrets.searxng_secret.path;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.k3s ];
      script = ''
        k3s kubectl create namespace searxng --dry-run=client --output yaml \
          | k3s kubectl apply --filename -

        k3s kubectl --namespace searxng create secret generic searxng \
          --from-file=SEARXNG_SECRET=${config.sops.secrets.searxng_secret.path} \
          --dry-run=client \
          --output yaml \
          | k3s kubectl apply --filename -
      '';
    };

    services.k3s.manifests.searxng.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "searxng";
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "searxng-settings";
          namespace = "searxng";
        };
        data."settings.yml" = ''
          use_default_settings: true

          search:
            default_lang: "da-DK"
            formats:
              - html
              - json
              - csv
              - rss

          server:
            port: 8080
            bind_address: "0.0.0.0"
            base_url: https://searxng.zaza.haahr.me/
            image_proxy: true
            method: "GET"

          ui:
            default_locale: "en"
            theme_args:
              simple_style: dark
            hotkeys: vim

          engines:
            - name: artic
              disabled: true
            - name: arxiv
              disabled: true
            - name: bing images
              disabled: true
            - name: bing news
              disabled: true
            - name: bing videos
              disabled: true
            - name: openverse
              disabled: true
            - name: chefkoch
              disabled: true
            - name: currency
              disabled: true
            - name: deviantart
              disabled: true
            - name: devicons
              disabled: true
            - name: docker hub
              disabled: true
            - name: etymonline
              disabled: true
            - name: flickr
              disabled: true
            - name: gentoo
              disabled: true
            - name: goodreads
              disabled: false
            - name: hackernews
              disabled: false
            - name: hoogle
              disabled: true
            - name: kickass
              disabled: true
            - name: lemmy communities
              disabled: true
            - name: lemmy users
              disabled: true
            - name: lemmy posts
              disabled: true
            - name: lemmy comments
              disabled: true
            - name: lingva
              disabled: true
            - name: lucide
              disabled: true
            - name: mastodon users
              disabled: true
            - name: mastodon hashtags
              disabled: true
            - name: mdn
              disabled: true
            - name: mixcloud
              disabled: true
            - name: mankier
              disabled: true
            - name: nyaa
              disabled: false
            - name: openairedatasets
              disabled: true
            - name: openairepublications
              disabled: true
            - name: pdbe
              disabled: true
            - name: pexels
              disabled: true
            - name: piratebay
              disabled: true
            - name: pypi
              disabled: true
            - name: radio browser
              disabled: true
            - name: reuters
              disabled: true
            - name: sepiasearch
              disabled: true
            - name: askubuntu
              disabled: true
            - name: semantic scholar
              disabled: true
            - name: startpage
              disabled: true
            - name: startpage news
              disabled: true
            - name: startpage images
              disabled: true
            - name: solidtorrents
              disabled: true
            - name: tmdb
              disabled: false
            - name: unsplash
              disabled: true
            - name: dailymotion
              disabled: true
            - name: vimeo
              disabled: true
            - name: wikinews
              disabled: true
            - name: wikicommons.images
              disabled: true
            - name: wikicommons.videos
              disabled: true
            - name: wikicommons.audio
              disabled: true
            - name: dictzone
              disabled: true
            - name: mymemory translated
              disabled: true
            - name: wordnik
              disabled: true
            - name: tootfinder
              disabled: true
            - name: wttr.in
              disabled: true
            - name: bt4g
              disabled: true
            - name: nixos wiki
              engine: mediawiki
              shortcut: nixw
              base_url: https://wiki.nixos.org/
              search_type: text
              disabled: false
              categories: [it, software wikis]

          doi_resolvers:
            oadoi.org: https://oadoi.org/
            doi.org: https://doi.org/
            sci-hub.se: https://sci-hub.se/
            sci-hub.st: https://sci-hub.st/
            sci-hub.ru: https://sci-hub.ru/

          default_doi_resolver: oadoi.org
        '';
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "searxng";
          namespace = "searxng";
          labels.app = "searxng";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "searxng";
          template = {
            metadata = {
              labels.app = "searxng";
              annotations."config.ph/settings-revision" = "2026-06-18-search-formats";
            };
            spec = {
              containers = [
                {
                  name = "searxng";
                  image = "searxng/searxng:latest";
                  env = [
                    {
                      name = "SEARXNG_SECRET";
                      valueFrom.secretKeyRef = {
                        name = "searxng";
                        key = "SEARXNG_SECRET";
                      };
                    }
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 8080;
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "settings";
                      mountPath = "/etc/searxng/settings.yml";
                      subPath = "settings.yml";
                      readOnly = true;
                    }
                  ];
                }
              ];
              enableServiceLinks = false;
              volumes = [
                {
                  name = "settings";
                  configMap.name = "searxng-settings";
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
          name = "searxng";
          namespace = "searxng";
        };
        spec = {
          selector.app = "searxng";
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
          name = "searxng";
          namespace = "searxng";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "searxng.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "searxng";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [
            {
              hosts = [ "searxng.zaza.haahr.me" ];
            }
          ];
        };
      }
    ];
  };
}
