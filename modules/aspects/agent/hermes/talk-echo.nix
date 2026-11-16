# The Echo speaker in the living room: hermes-talk's Wyoming surface, linked to
# the Echo on the IoT VLAN. A unit of its own, so an Echo reboot or a crashed
# link restarts it without touching the gateway.
_: {
  flake.modules.homeManager.agent-hermes =
    { config, lib, ... }:
    {
      systemd.user.services.talk-echo = {
        Unit = {
          Description = "hermes-talk voice on the Echo speaker";
          After = [ "hermes-agent.service" ];
        };
        Service = {
          ExecStart = "${lib.getExe' config.programs.hermes-agent.package "hermes"} talk echo 10.0.40.177";
          # The gateway's environment (HERMES_HOME, the same hermes build), then
          # a PATH that also reaches the system's `openhome`: home_control is
          # offered only where that CLI is found. systemd keeps the last PATH.
          Environment = config.systemd.user.services.hermes-agent.Service.Environment ++ [
            "PATH=${lib.makeBinPath [ config.programs.hermes-agent.package ]}:/run/current-system/sw/bin"
            "TALK_IDENTITY_INCLUDE=PERSONA,WORKING"
            "TALK_TURN_DETECTION=semantic_vad"
            "TALK_SEMANTIC_EAGERNESS=medium"
            # A room speaker in a home that speaks English and Danish.
            "TALK_NOISE_REDUCTION=far_field"
            "TALK_LANGUAGES=English, Danish"
          ];
          WorkingDirectory = config.home.homeDirectory;
          Restart = "always";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
