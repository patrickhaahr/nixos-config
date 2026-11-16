_: {
  # Self-hosted firecrawl as podman containers on one network. Images are
  # pinned by digest; bump them deliberately.
  flake.modules.nixos.homelab-firecrawl =
    { config, lib, ... }:
    let
      network = "firecrawl";
      apiPort = 3002;
      firecrawlImage = "ghcr.io/firecrawl/firecrawl@sha256:a8dadf0db956fd907ddd89b7ba4d77fa9bb38fd8b10d3e1da3d7b1fe181f4793";

      common = {
        networks = [ network ];
        environmentFiles = [ config.sops.templates."firecrawl.env".path ];
      };

      firecrawlProcess =
        group: script: heap:
        common
        // {
          image = firecrawlImage;
          entrypoint = "node";
          cmd = [
            "--max-old-space-size=${toString heap}"
            script
          ];
          environment = {
            HOST = "0.0.0.0";
            FLY_PROCESS_GROUP = group;
            REDIS_URL = "redis://redis:6379";
            REDIS_RATE_LIMIT_URL = "redis://redis:6379";
            PLAYWRIGHT_MICROSERVICE_URL = "http://playwright-service:3000/scrape";
            SEARXNG_ENDPOINT = "https://searxng.zaza.haahr.me/";
            USE_DB_AUTHENTICATION = "false";
            ENV = "production";
            LOGGING_LEVEL = "INFO";
          };
          dependsOn = [
            "firecrawl-redis"
            "firecrawl-postgres"
            "firecrawl-playwright"
          ];
        };

      containers = {
        firecrawl-api = firecrawlProcess "app" "dist/src/index.js" 6144 // {
          ports = [ "127.0.0.1:${toString apiPort}:${toString apiPort}" ];
        };
        firecrawl-worker = firecrawlProcess "worker" "dist/src/services/queue-worker.js" 3072;
        firecrawl-nuq-worker = firecrawlProcess "nuq-worker" "dist/src/services/worker/nuq-worker.js" 3072;

        firecrawl-playwright = common // {
          image = "ghcr.io/firecrawl/playwright-service@sha256:227ce3d8059173925a5a0697c63a1e947662cca934a609151651f578774edd5d";
          environment = {
            PORT = "3000";
            ALLOW_LOCAL_WEBHOOKS = "false";
          };
          extraOptions = [ "--network-alias=playwright-service" ];
        };

        firecrawl-postgres = common // {
          image = "ghcr.io/firecrawl/nuq-postgres@sha256:d719b36160eac2fcbe16dc7e7360ddb9c82c40ea5da183d07bf4a755c6a0b2ae";
          environment = {
            POSTGRES_USER = "postgres";
            POSTGRES_DB = "postgres";
          };
          volumes = [ "firecrawl-postgres:/var/lib/postgresql/data" ];
          extraOptions = [ "--network-alias=nuq-postgres" ];
        };

        firecrawl-redis = {
          image = "docker.io/library/redis@sha256:71885d8cc6e42f2bc0aa2eb853bfc4be200b5108a46ac50e117ae1df0531fb80";
          networks = [ network ];
          extraOptions = [ "--network-alias=redis" ];
        };
      };
    in
    {
      sops.secrets = {
        firecrawl_bull_auth_key = { };
        firecrawl_postgres_password = { };
      };
      sops.templates."firecrawl.env".content = ''
        BULL_AUTH_KEY=${config.sops.placeholder.firecrawl_bull_auth_key}
        POSTGRES_PASSWORD=${config.sops.placeholder.firecrawl_postgres_password}
        NUQ_DATABASE_URL=postgresql://postgres:${config.sops.placeholder.firecrawl_postgres_password}@nuq-postgres:5432/postgres
      '';

      virtualisation.oci-containers.containers = containers;

      systemd = {
        services = {
          podman-network-firecrawl = {
            description = "Podman network for firecrawl";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            path = [ config.virtualisation.podman.package ];
            script = "podman network exists ${network} || podman network create ${network}";
          };
        }
        // lib.mapAttrs' (
          name: _:
          lib.nameValuePair "podman-${name}" {
            requires = [ "podman-network-firecrawl.service" ];
            after = [ "podman-network-firecrawl.service" ];
          }
        ) containers;
      };

      services.nginx.virtualHosts."firecrawl.zaza.haahr.me".locations."/".proxyPass =
        "http://127.0.0.1:${toString apiPort}";
    };
}
