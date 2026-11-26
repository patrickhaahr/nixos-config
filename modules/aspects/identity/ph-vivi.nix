{ self, ... }:
{
  flake.modules.nixos.identity-ph-vivi = {
    imports = [ self.modules.nixos.home-manager ];

    users.users.ph = {
      isNormalUser = true;
      extraGroups = [
        "video"
        "wheel"
      ];
      openssh.authorizedKeys.keyFiles = [ ./ph-vivi.pub ];
    };
    security.sudo.wheelNeedsPassword = false;

    home-manager.users.ph = {
      imports = [
        self.modules.homeManager.identity-ph
        self.modules.homeManager.nushell
      ];
      programs.neovim.enable = true;
      home.stateVersion = "26.05";
    };
  };
}
