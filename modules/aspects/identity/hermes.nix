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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3MkX3J3hR13KTzSkeHF2Uxhh3U0EALHicW+gYMufFD patrickhaahr@WinBad"
      ];
      extraGroups = [
        "systemd-journal"
        "wheel"
      ];
    };

    home-manager.users.hermes = {
      imports = [
        self.modules.homeManager.agent-hermes
        self.modules.homeManager.browser-use
        self.modules.homeManager.agent-tools
        self.modules.homeManager.agent-browser
        self.modules.homeManager.browse-headless
      ];
      programs.yt-dlp.enable = true;
      home.stateVersion = "25.11";
    };

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user == "hermes" &&
            action.id == "org.freedesktop.systemd1.manage-units") {
          return polkit.Result.YES;
        }
      });
    '';

    systemd.tmpfiles.rules = [
      "d /home/hermes/.config 0700 hermes users -"
      "d /home/hermes/.local 0700 hermes users -"
      "d /home/hermes/.local/share 0700 hermes users -"
      "d /home/hermes/.cache 0700 hermes users -"
    ];
  };
}
