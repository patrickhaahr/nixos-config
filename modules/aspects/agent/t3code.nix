{ self, ... }:
{
  # Declarative stand-in for `t3 service install`: a hermes systemd user service
  # (survives logout via the user's linger) running the nixpkgs build. Do not
  # use `t3 service`/`t3 update`; they install unmanaged downloaded releases.
  flake.modules.nixos.t3code-service = {
    home-manager.users.hermes.imports = [ self.modules.homeManager.t3code-service ];

    # https://t3code.zaza.haahr.me: traefik (in k3s) proxies to the host
    # process via the cni0 bridge IP, which the firewall already trusts. No
    # selector, so the EndpointSlice is the only backend.
    services.k3s.manifests.t3code.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "t3code";
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "t3code";
          namespace = "t3code";
        };
        spec.ports = [
          {
            name = "http";
            port = 3773;
            targetPort = 3773;
          }
        ];
      }
      {
        apiVersion = "discovery.k8s.io/v1";
        kind = "EndpointSlice";
        metadata = {
          name = "t3code-host";
          namespace = "t3code";
          labels."kubernetes.io/service-name" = "t3code";
        };
        addressType = "IPv4";
        endpoints = [ { addresses = [ "10.42.0.1" ]; } ];
        ports = [
          {
            name = "http";
            port = 3773;
            protocol = "TCP";
          }
        ];
      }
      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "t3code";
          namespace = "t3code";
          annotations = {
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
            "traefik.ingress.kubernetes.io/router.tls" = "true";
            "traefik.ingress.kubernetes.io/router.tls.certresolver" = "cloudflare";
          };
        };
        spec = {
          rules = [
            {
              host = "t3code.zaza.haahr.me";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "t3code";
                    port.name = "http";
                  };
                }
              ];
            }
          ];
          tls = [ { hosts = [ "t3code.zaza.haahr.me" ]; } ];
        };
      }
    ];
  };

  flake.modules.homeManager.t3code-service =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.t3code ];

      # Same unit name as upstream, so `systemctl --user status t3code` works.
      systemd.user.services.t3code = {
        Unit = {
          Description = "T3 Code headless server";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Environment = [
            # Agents spawned by t3 need the user's HM profile (claude, opencode, ...).
            "PATH=/run/wrappers/bin:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
            # Telemetry goes to PostHog; opt out (also stops "Failed to flush telemetry" log spam).
            "T3CODE_TELEMETRY_ENABLED=false"
          ];
          # Tailscale Serve stays off: `--tailscale-serve` binds port 443 on the
          # tailnet IP and breaks traefik's TLS for *.zaza.haahr.me. Listening on
          # all interfaces is needed so traefik can reach it via cni0; the firewall
          # keeps 3773 closed on the LAN and tailnet.
          ExecStart = "${pkgs.t3code}/bin/t3 serve --no-browser --mode web --host 0.0.0.0 --port 3773";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
