{ self, ... }:
{

  flake.modules.nixos.t3code-service =
    { config, ... }:
    {
      imports = [ self.modules.nixos.t3code-package ];

      home-manager.users.hermes.imports = [ self.modules.homeManager.t3code-service ];

      services.nginx.virtualHosts."t3code.${config.homelab.domain}".locations."/" = {
        proxyPass = "http://127.0.0.1:3773";
        proxyWebsockets = true;
      };
    };

  flake.modules.homeManager.t3code-service =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.t3code ];

      systemd.user.services.t3code = {
        Unit = {
          Description = "T3 Code headless server";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Environment = [

            "PATH=/run/wrappers/bin:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"

            "T3CODE_TELEMETRY_ENABLED=false"
          ];

          ExecStart = "${pkgs.t3code}/bin/t3 serve --no-browser --mode web --host 127.0.0.1 --port 3773";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
