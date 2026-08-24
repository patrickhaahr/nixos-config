_: {
  flake.modules.nixos.openssh = _: {
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

  flake.modules.homeManager.openssh =
    { lib, pkgs, ... }:
    {
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
          "uranus" = {
            HostName = "100.118.180.74";
            User = "root";
            IdentityAgent = "none";
            IdentityFile = "~/.ssh/id_ed25519_uranus";
            IdentitiesOnly = true;
          };
          "zaza" = {
            User = "ph";
            IdentityAgent = "none";
            IdentityFile = "~/.ssh/id_ed25519_zaza";
            IdentitiesOnly = true;
          };
          "hermes" = {
            HostName = "zaza";
            User = "hermes";
            IdentityAgent = "none";
            IdentityFile = "~/.ssh/nika-to-hermes-auto";
            IdentitiesOnly = true;
          };
        };
      };

      home.activation.materializeSshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="$HOME/.ssh/config"
        if [ -L "$cfg" ]; then
          src="$(readlink "$cfg")"
          rm "$cfg"
          ${pkgs.coreutils}/bin/install -m 600 "$src" "$cfg"
        fi
      '';

      services.ssh-agent.enable = true;
    };
}
