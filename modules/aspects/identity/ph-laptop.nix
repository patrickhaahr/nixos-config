{ self, ... }:
let
  userName = "ph";
in
{
  flake.modules.nixos.identity-ph-laptop = {
    imports = [
      self.modules.nixos.identity-ph-headless
      self.modules.nixos.ghostty
      self.modules.nixos.noctalia
    ];

    services.greetd.settings.default_session.user = userName;

    users.users.${userName}.extraGroups = [
      "networkmanager"
      "i2c"
    ];
    home-manager.users.${userName} = {
      imports = [
        self.modules.homeManager.cursor
        self.modules.homeManager.noctalia
        self.modules.homeManager.ghostty
        self.modules.homeManager.agent-hermes-desktop
      ];
    };
  };
}
