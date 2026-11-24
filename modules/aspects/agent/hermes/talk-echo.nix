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

          Environment = config.systemd.user.services.hermes-agent.Service.Environment ++ [
            "PATH=${lib.makeBinPath [ config.programs.hermes-agent.package ]}:/run/current-system/sw/bin"
            "TALK_IDENTITY_INCLUDE=PERSONA,WORKING"
            "TALK_TURN_DETECTION=server_vad"
            "TALK_NOISE_REDUCTION=off"
            "TALK_LANGUAGES=English,Danish"
          ];
          WorkingDirectory = config.home.homeDirectory;
          Restart = "always";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
