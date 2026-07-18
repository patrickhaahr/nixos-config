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
        self.modules.homeManager.ghostty
      ];

      home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
        defaultWallpaper = "/home/ph/nixos-config/wallpaper/a_cartoon_of_a_girl_with_blue_hair_and_a_skull.jpg";
      };
    };
  };
}
