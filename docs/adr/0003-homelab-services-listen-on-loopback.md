# Homelab services listen on loopback behind nginx

zaza's web services bind to loopback and nginx terminates TLS for `*.zaza.haahr.me` (tailnet-only names; each homelab host gets its own `*.<host>.haahr.me` wildcard through `homelab.domain`, because a wildcard covers only one label), so no service handles certificates. Only nginx (80/443), the Wazuh agent ports (1514/1515) and the harmonia binary cache (tailnet interface only) are reachable from outside the host.

- `homelab-proxy` re-declares the `virtualHosts` submodule option; NixOS merges a re-declared submodule into the upstream one, so every vhost on the host defaults to the wildcard cert and the HTTPS redirect.
- The ACME DNS-01 challenge waits a fixed time instead of checking propagation: the router hijacks all port-53 traffic to AdGuard, whose cache never sees the fresh TXT record, so propagation checks time out.
- T3 Code keeps Tailscale Serve off: `--tailscale-serve` binds port 443 on the tailnet IP, where nginx already listens.
- Containers listen on all interfaces inside their network namespace but publish their web port only on `127.0.0.1`, so nginx is still the only way in.
- Wazuh runs upstream's dashboard config with server TLS off, because nginx terminates TLS in front of it.
- LibreSpeed's backend binds to `127.0.0.1`, because nginx proxies `/backend/` to it.
- SearXNG drops the default extra uwsgi `http = ":8080"` listener, which collides with Hermes' signal-cli; nginx talks to the uwsgi socket.
- Loki's frontend address and ring instance address are pinned to `127.0.0.1`: the querier dials the frontend at its advertised address, which defaults to the LAN IP and misses the loopback gRPC listener.
- Hermes' dashboard backend accepts only its bound host or `public_url`, so `public_url` names the nginx vhost.
