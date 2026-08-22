_: {
  flake.modules.nixos.homelab-hermes-signal-cli =
    { config, pkgs, ... }:
    {
      systemd.services.signal-cli = {
        description = "signal-cli HTTP daemon for Hermes";
        after = [
          "network-online.target"
          "hermes-provision.service"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        environment.HOME = "/home/hermes";
        serviceConfig = {
          User = "hermes";
          Group = "hermes";
          Restart = "on-failure";
          RestartSec = 5;
          ExecStart = "${pkgs.signal-cli}/bin/signal-cli --config /home/hermes/.signal-cli daemon --http 127.0.0.1:8080";
        };
      };
    };
}
