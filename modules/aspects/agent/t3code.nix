{ self, ... }:
{
  # Declarative stand-in for `t3 service install`: a hermes systemd user service
  # (survives logout via the user's linger) running the nixpkgs build. Do not
  # use `t3 service`/`t3 update`; they install unmanaged downloaded releases.
  flake.modules.nixos.t3code-service = {
    imports = [ self.modules.nixos.t3code-package ];

    home-manager.users.hermes.imports = [ self.modules.homeManager.t3code-service ];

    services.nginx.virtualHosts."t3code.zaza.haahr.me".locations."/" = {
      proxyPass = "http://127.0.0.1:3773";
      proxyWebsockets = true;
    };
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
          # tailnet IP, where nginx terminates TLS for *.zaza.haahr.me.
          ExecStart = "${pkgs.t3code}/bin/t3 serve --no-browser --mode web --host 127.0.0.1 --port 3773";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
