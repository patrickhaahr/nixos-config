{ self, ... }:
{
  flake.modules.nixos.identity-hermes = { pkgs, ... }: {
    users.users.hermes = {
      isNormalUser = true;
      description = "Hermes Agent";
      # Gateway/dashboard will migrate here; keep services alive without login.
      linger = true;
      shell = pkgs.bashInteractive;
      # Inbound: who may SSH INTO hermes@host (starts as ph's keys; replace
      # with dedicated agent keys whenever). Outbound keys live in
      # /home/hermes/.ssh and are provisioned separately.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFRDoMg0lCDaI7cG3C5wcRtRz2gJXbFYDemOK+KLS5U nika"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMUfyFxXSDBxnLaAKTUVuQ+INsS8C0k83RJ9kkNJM0Y nika-to-hermes"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHs0OHmxy5J5jg/9RJ/sHhIRGXi3UkkJeko0/TSvNVh6 nika-to-hermes-auto"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWIIdTomMDrLElXLqDg68u7h8Ila5Rjg5TZIngPMUeH ph@loki"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBow0SMe+E5nrSuhmq45vcb/CzYEHQsPANx5vGNRksR8 grapheneos"
      ];
      # Read access to system journals for self-debugging.
      extraGroups = [ "systemd-journal" ];
    };

    # Second Home Manager account: the entire hermes runtime stack (gateway,
    # dashboard backend, signal-cli daemon, sops-rendered env) runs here,
    # reusing the agent aspects unchanged.
    home-manager.users.hermes = {
      imports = [
        self.modules.homeManager.agent-hermes
        # .envrc in the nixos-config clone needs this to run `just verify`.
        self.modules.homeManager.direnv
        # Agent harnesses; opencode projects agents/ to ~/.agents, pi to ~/.pi/agent.
        self.modules.homeManager.opencode
        self.modules.homeManager.pi
        # Agent CLI toolkit: fetch/parse, inspect, transform.
        self.modules.homeManager.yt-dlp
        self.modules.homeManager.jq
        self.modules.homeManager.python3
        self.modules.homeManager.ripgrep
        self.modules.homeManager.fd
        self.modules.homeManager.file
        self.modules.homeManager.unzip
        self.modules.homeManager.sqlite
        self.modules.homeManager.tree
        self.modules.homeManager.hunk
      ];
      home.stateVersion = "25.11";
    };

    # sops-install-secrets creates parent dirs of rendered secrets as root;
    # hand them back to hermes so HM activation can write into its home.
    systemd.tmpfiles.rules = [
      "d /home/hermes/.config 0700 hermes users -"
      "d /home/hermes/.local 0700 hermes users -"
      "d /home/hermes/.local/share 0700 hermes users -"
      "d /home/hermes/.cache 0700 hermes users -"
    ];
  };
}
