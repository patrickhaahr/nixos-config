{ ... }: {
  flake.modules.nixos.openssh = { ... }: {
    services.openssh = {
      enable = true;
      settings = {
        AllowUsers = [ "ph" ];
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        AllowAgentForwarding = false;
        AllowTcpForwarding = false;
        MaxAuthTries = 3;
        MaxSessions = 2;
        LoginGraceTime = "30s";
      };
    };
  };

  flake.modules.homeManager.openssh = { ... }: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
        "github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };
      };
    };

    services.ssh-agent.enable = true;
  };
}
