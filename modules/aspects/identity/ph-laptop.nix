{ self, ... }:
let
  userName = "ph";
in
{
  flake.modules.nixos.identity-ph-laptop = {
    imports = [ self.modules.nixos.identity-ph-headless ];

    users.users.${userName}.extraGroups = [
      "networkmanager"
      "i2c"
    ];
    home-manager.users.${userName} = {
      imports = [
        self.modules.homeManager.cursor
        self.modules.homeManager.noctalia-wallpapers
        self.modules.homeManager.ghostty
        self.modules.homeManager.agent-hermes-desktop
      ];
    };
  };
}
