{ self, ... }:
let
  userName = "ph";
in
{
  flake.modules.nixos.identity-ph-desktop = {
    imports = [
      self.modules.nixos.identity-ph-graphical
    ];

    users.users.${userName}.extraGroups = [
      "dialout"
      "input"
      "docker"
    ];
    home-manager.users.${userName} = {
      imports = [
        self.modules.homeManager.identity-ph-desktop
        self.modules.homeManager.agent-browser
        self.modules.homeManager.agent-specialists
        self.modules.homeManager.browse
        self.modules.homeManager.openhome

        self.modules.homeManager.osu-lazer
        self.modules.homeManager.typesafe
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
