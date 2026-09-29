{
  flake.modules.nixos.homelab-t3code-serve =
    { pkgs, ... }:
    {
      # Tailscale Serve is disabled: `--tailscale-serve` binds port 443 on the
      # tailnet IP and breaks traefik's TLS for *.zaza.haahr.me.
      systemd.services.t3code-serve = {
        description = "T3 Code headless server";
        after = [
          "tailscaled.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          # Agent state (projects, pairings) lives under the hermes home.
          User = "hermes";
          ExecStart = "${pkgs.t3code}/bin/t3 serve --no-browser --mode web";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
