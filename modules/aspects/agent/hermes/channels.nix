_: {
  flake.modules.homeManager.agent-hermes =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.signal-cli
      ];

      systemd.user.services.signal-cli = {
        Unit = {
          Description = "signal-cli HTTP daemon for hermes";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${pkgs.signal-cli}/bin/signal-cli daemon --http 127.0.0.1:8080";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
