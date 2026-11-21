{ self, ... }:
let
  userName = "ph";
in
{
  flake.modules.nixos.identity-ph-desktop = {
    imports = [
      self.modules.nixos.identity-ph-headless
      self.modules.nixos.ghostty
      self.modules.nixos.noctalia
    ];

    services.greetd.settings.default_session.user = userName;

    users.users.${userName}.extraGroups = [
      "networkmanager"
      "dialout"
      "i2c"
      "input"
      "docker"
    ];
    home-manager.users.${userName} = {
      imports = [
        self.modules.homeManager.identity-ph-desktop
        self.modules.homeManager.agent-browser
        self.modules.homeManager.browse

        self.modules.homeManager.ghostty
        self.modules.homeManager.cursor
        self.modules.homeManager.noctalia
        self.modules.homeManager.osu-lazer
        self.modules.homeManager.steam-hm
        self.modules.homeManager.typesafe
        self.modules.homeManager.agent-hermes-desktop
      ];
    };
  };

  flake.modules.homeManager.identity-ph-desktop = _: {
    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };
  };
}
