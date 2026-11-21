{ self, ... }:
{

  flake.modules.nixos.homelab-firecrawl =
    { config, ... }:
    let
      apiPort = 3002;
      firecrawlImage = "ghcr.io/firecrawl/firecrawl:latest@sha256:e12baea631bc48c30566403166192735c2e31b0232aed81274c9a6dea67d1d19";

      common.environmentFiles = [ config.sops.templates."firecrawl.env".path ];

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
          image = "ghcr.io/firecrawl/playwright-service:latest@sha256:227ce3d8059173925a5a0697c63a1e947662cca934a609151651f578774edd5d";
          environment = {
            PORT = "3000";
            ALLOW_LOCAL_WEBHOOKS = "false";
          };
          extraOptions = [ "--network-alias=playwright-service" ];
        };

        firecrawl-postgres = common // {
          image = "ghcr.io/firecrawl/nuq-postgres:latest@sha256:d719b36160eac2fcbe16dc7e7360ddb9c82c40ea5da183d07bf4a755c6a0b2ae";
          environment = {
            POSTGRES_USER = "postgres";
            POSTGRES_DB = "postgres";
          };
          volumes = [ "firecrawl-postgres:/var/lib/postgresql/data" ];
          extraOptions = [ "--network-alias=nuq-postgres" ];
        };

        firecrawl-redis = {
          image = "docker.io/library/redis:alpine@sha256:7958cfbb9d152f87dadfbc89f1b0b15938f0b81ff8982feb327476f4911935c3";
          extraOptions = [ "--network-alias=redis" ];
        };
      };
    in
    {
      imports = [ self.modules.nixos.homelab-podman ];

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

      homelab.podmanNetworks.firecrawl = builtins.attrNames containers;

      services.nginx.virtualHosts."firecrawl.zaza.haahr.me".locations."/".proxyPass =
        "http://127.0.0.1:${toString apiPort}";
    };
}
