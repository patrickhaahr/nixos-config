{ self, ... }:
let
  userName = "ph";
in {
  flake.modules.nixos.identity-ph-desktop = { lib, config, ... }:
    let
      handyConfigured = builtins.hasAttr "programs" config && builtins.hasAttr "handy" config.programs;
    in {
      imports = [ self.modules.nixos.identity-ph-headless ];

      users.users.${userName}.extraGroups = [ "networkmanager" "i2c" "docker" ];
      home-manager.users.${userName} = {
        imports = [
          self.modules.homeManager.identity-ph-desktop
          self.modules.homeManager.agent-browser
          #self.modules.homeManager.hacking
          self.modules.homeManager.handy
          self.modules.homeManager.ghostty
          self.modules.homeManager.cursor
          self.modules.homeManager.steam-hm
        ];

        services.handy = lib.mkIf (handyConfigured && config.programs.handy.autostart) {
          enable = true;
          package = config.programs.handy.package;
        };
      };
    };

  flake.modules.homeManager.identity-ph-desktop = { ... }: {
    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };
    home.file."tmp/vj-noctalia-cache/wallpapers.json".text = builtins.toJSON {
      defaultWallpaper = "/home/ph/nixos-config/wallpaper/a_woman_holding_a_sword.jpg";
      wallpapers = {
        "HDMI-A-1" = "/home/ph/nixos-config/wallpaper/a_woman_holding_a_sword.jpg";
      };
    };
  };
}
