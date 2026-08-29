{ self, ... }:
{
  flake.modules.nixos.identity-hermes = { pkgs, ... }: {
    users.users.hermes = {
      isNormalUser = true;
      description = "Hermes Agent";
      linger = true;
      shell = pkgs.bashInteractive;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFRDoMg0lCDaI7cG3C5wcRtRz2gJXbFYDemOK+KLS5U nika"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMUfyFxXSDBxnLaAKTUVuQ+INsS8C0k83RJ9kkNJM0Y nika-to-hermes"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHs0OHmxy5J5jg/9RJ/sHhIRGXi3UkkJeko0/TSvNVh6 nika-to-hermes-auto"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWIIdTomMDrLElXLqDg68u7h8Ila5Rjg5TZIngPMUeH ph@loki"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBow0SMe+E5nrSuhmq45vcb/CzYEHQsPANx5vGNRksR8 grapheneos"
      ];
      extraGroups = [ "systemd-journal" ];
    };

    home-manager.users.hermes = {
      imports = [
        self.modules.homeManager.agent-hermes
        self.modules.homeManager.bash
        self.modules.homeManager.direnv
        self.modules.homeManager.opencode
        self.modules.homeManager.pi
        self.modules.homeManager.browser-use
        self.modules.homeManager.yt-dlp
        self.modules.homeManager.jq
        self.modules.homeManager.less
        # no `python3` aspect here: browser-use-env already provides `bin/python3`
        # and a second interpreter collides in the buildEnv (home-manager-path)
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

    systemd.tmpfiles.rules = [
      "d /home/hermes/.config 0700 hermes users -"
      "d /home/hermes/.local 0700 hermes users -"
      "d /home/hermes/.local/share 0700 hermes users -"
      "d /home/hermes/.cache 0700 hermes users -"
    ];
  };
}
