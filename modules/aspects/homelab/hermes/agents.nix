_: {
  flake.modules.nixos.homelab-hermes-agents =
    { lib, pkgs, ... }:
    let
      hermesHome = "/home/hermes";
      hermesVenvBin = "${hermesHome}/.venv/bin";
      toolPath = "${
        lib.makeBinPath [
          pkgs.chromium
          pkgs.ffmpeg
          pkgs.git
          pkgs.nodejs
          pkgs.ripgrep
          pkgs.uv
          pkgs.yt-dlp
        ]
      }:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin";
    in
    {
      systemd.services = {
        hermes-bootstrap = {
          description = "Install hermes-agent venv for the hermes user";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          before = [
            "hermes-gateway.service"
            "hermes-dashboard.service"
          ];
          unitConfig.ConditionPathExists = "!${hermesVenvBin}/hermes";
          serviceConfig = {
            Type = "oneshot";
            User = "hermes";
            Group = "hermes";
          };
          environment.HOME = hermesHome;
          script = ''
            ${pkgs.uv}/bin/uv venv ${hermesHome}/.venv --python ${pkgs.python312}/bin/python3
            VIRTUAL_ENV=${hermesHome}/.venv ${pkgs.uv}/bin/uv pip install \
              --python ${hermesVenvBin}/python \
              "hermes-agent[voice,web,youtube,mcp]"
          '';
        };

        hermes-gateway = {
          description = "Hermes agent messaging gateway";
          after = [
            "network-online.target"
            "hermes-bootstrap.service"
            "hermes-provision.service"
            "signal-cli.service"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            HOME = hermesHome;
            HERMES_HOME = "${hermesHome}/.hermes";
            PATH = lib.mkForce toolPath;
            SIGNAL_HTTP_URL = "http://127.0.0.1:8080";
            SEARXNG_URL = "https://searxng.zaza.haahr.me/";
            TERMINAL_ENV = "local";
            AGENT_BROWSER_ARGS = "--no-sandbox,--disable-dev-shm-usage";
            BROWSER_INACTIVITY_TIMEOUT = "300";
            API_SERVER_ENABLED = "true";
            API_SERVER_HOST = "0.0.0.0";
            API_SERVER_PORT = "8642";
          };
          serviceConfig = {
            User = "hermes";
            Group = "hermes";
            WorkingDirectory = hermesHome;
            EnvironmentFile = "${hermesHome}/.hermes/.env";
            ExecStartPre = "-${pkgs.procps}/bin/pkill -u hermes -f '/bin/hermes gateway'";
            ExecStart = "${hermesVenvBin}/hermes gateway run";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        hermes-dashboard = {
          description = "Hermes agent dashboard";
          after = [
            "network-online.target"
            "hermes-bootstrap.service"
            "hermes-provision.service"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            HOME = hermesHome;
            HERMES_HOME = "${hermesHome}/.hermes";
            PATH = lib.mkForce toolPath;
            HERMES_DASHBOARD_PUBLIC_URL = "http://zaza:9119";
          };
          serviceConfig = {
            User = "hermes";
            Group = "hermes";
            WorkingDirectory = hermesHome;
            EnvironmentFile = "${hermesHome}/.hermes/.env";
            ExecStartPre = "-${pkgs.procps}/bin/pkill -u hermes -f '/bin/hermes dashboard'";
            ExecStart = "${hermesVenvBin}/hermes dashboard --host 0.0.0.0 --port 9119 --no-open";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
    };
}
