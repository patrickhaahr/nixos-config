_: {
  flake.modules.nixos.homelab-prometheus =
    { config, ... }:
    let
      cfg = config.services.prometheus;
      node = cfg.exporters.node;
    in
    {
      services.prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
        retentionTime = "15d";
        globalConfig = {
          scrape_interval = "60s";
          evaluation_interval = "60s";
        };
        exporters.node = {
          enable = true;
          listenAddress = "127.0.0.1";
          enabledCollectors = [ "systemd" ];
        };
        scrapeConfigs = [
          {
            job_name = "prometheus";
            static_configs = [ { targets = [ "127.0.0.1:${toString cfg.port}" ]; } ];
          }
          {
            job_name = "node";
            static_configs = [ { targets = [ "127.0.0.1:${toString node.port}" ]; } ];
          }
        ];
      };

      services.nginx.virtualHosts."prometheus.zaza.haahr.me".locations."/".proxyPass =
        "http://127.0.0.1:${toString cfg.port}";
    };
}
