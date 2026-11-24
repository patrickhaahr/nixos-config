_: {
  flake.modules.nixos.homelab-dns-over-https =
    { config, ... }:
    {
      services.nginx.virtualHosts."dns.${config.homelab.domain}".locations = {
        "/".return = "404";
        "= /dns-query" = {
          proxyPass = "http://10.0.10.1:3000";
          extraConfig = ''
            access_log off;
            allow 10.0.0.0/8;
            allow 172.16.0.0/12;
            allow 192.168.0.0/16;
            allow 100.64.0.0/10;
            allow 127.0.0.0/8;
            allow fc00::/7;
            allow fe80::/10;
            allow ::1;
            deny all;
          '';
        };
      };
    };
}
