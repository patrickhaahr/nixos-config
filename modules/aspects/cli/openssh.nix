{ ... }: {
  flake.modules.nixos.openssh = { ... }: {
    services.openssh = {
      enable = true;
      settings = {
        AllowUsers = [ "ph" "patrickhaahr" ];
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
      matchBlocks."*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      matchBlocks."github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github";
        identitiesOnly = true;
      };
    };

    services.ssh-agent.enable = true;
  };
}
