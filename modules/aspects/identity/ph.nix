{ self, ... }:
let
  userName = "ph";
in {
  flake.modules.nixos.identity-ph = { pkgs, ... }: {
    users.users.${userName} = {
      isNormalUser = true;
      description = userName;
      extraGroups = [ "networkmanager" "wheel" ];
      shell = pkgs.nushell;
      packages = with pkgs; [ ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHug5lTw2U4y3umUuePSqFJH+t7dEEvlqDUroVIpPKF patrickhaahr@archbtw"
      ];
    };
    home-manager.users.${userName}.imports = [
      self.modules.homeManager.identity-ph
      self.modules.homeManager.git
      self.modules.homeManager.openssh
      self.modules.homeManager.neovim
      self.modules.homeManager.nushell
      self.modules.homeManager.opencode
      self.modules.homeManager.ghostty
      self.modules.homeManager.cursor
    ];
  };

  flake.modules.homeManager.identity-ph = { lib, pkgs, ... }: {
    home.username = lib.mkDefault userName;
    home.homeDirectory = lib.mkDefault (
      if pkgs.stdenvNoCC.isDarwin then "/Users/${userName}" else "/home/${userName}"
    );
    home.stateVersion = lib.mkDefault "25.11";
    home.file."tmp/vj-noctalia-cache/wallpapers.json".text = builtins.toJSON {
      defaultWallpaper = "/home/ph/nixos-config/wallpaper/a_woman_holding_a_sword.jpg";
      wallpapers = {
        "HDMI-A-1" = "/home/ph/nixos-config/wallpaper/a_woman_holding_a_sword.jpg";
      };
    };
  };
}
