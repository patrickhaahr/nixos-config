{
  flake.modules.nixos.homelab-t3code-serve =
    { pkgs, ... }:
    {
      # `t3 serve --tailscale-serve` drives the tailscale CLI; grant operator to the run user.
      systemd.services.t3code-serve = {
        description = "T3 Code headless server (Tailscale Serve)";
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
          ExecStartPre = "${pkgs.tailscale}/bin/tailscale set --operator=hermes";
          ExecStart = "${pkgs.t3code}/bin/t3 serve --tailscale-serve --no-browser --mode web";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
