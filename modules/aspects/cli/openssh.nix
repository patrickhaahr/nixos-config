_: {
  flake.modules.nixos.openssh = _: {
    # OpenSSH rejects systemd's store-owned proxy drop-in for non-root users.
    programs.ssh.systemd-ssh-proxy.enable = false;

    services.openssh = {
      enable = true;
      settings = {
        AllowUsers = [
          "ph"
          "hermes"
        ];
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

  flake.modules.homeManager.openssh = _: {
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
          IdentityAgent = "none";
          IdentityFile = [
            "~/.ssh/id_ed25519_sk_yk1"
            "~/.ssh/id_ed25519_sk_yk2"
            "~/.ssh/id_ed25519_github"
          ];
          IdentitiesOnly = true;
        };
        # Prefer the router-specific key once it is authorized.
        "router" = {
          User = "root";
          IdentityFile = [
            "~/.ssh/id_ed25519_router"
            "~/.ssh/id_ed25519"
          ];
          IdentitiesOnly = true;
        };
        # Ghostty's TERM=xterm-ghostty is meaningless to hosts without its
        # terminfo (e.g. headless zaza); downgrade for these destinations.
        "zaza" = {
          User = "ph";
          IdentityAgent = "none";
          IdentityFile = "~/.ssh/id_ed25519_zaza";
          IdentitiesOnly = true;
          SetEnv = {
            TERM = "xterm-256color";
          };
        };
        "hermes" = {
          HostName = "zaza";
          User = "hermes";
          IdentityAgent = "none";
          IdentityFile = "~/.ssh/nika-to-hermes-auto";
          IdentitiesOnly = true;
          SetEnv = {
            TERM = "xterm-256color";
          };
        };
      };
    };

    services.ssh-agent.enable = true;
  };
}
