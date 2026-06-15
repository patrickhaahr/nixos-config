{ self, ... }:
let
  userName = "wsl";
in {
  flake.modules.nixos.identity-wsl = { pkgs, ... }: {
    users.users.${userName} = {
      isNormalUser = true;
      description = userName;
      extraGroups = [ "wheel" ];
      shell = pkgs.nushell;
    };

    home-manager.users.${userName}.imports = [
      self.modules.homeManager.identity-wsl
      self.modules.homeManager.agent-browser
      self.modules.homeManager.direnv
      self.modules.homeManager.gh
      self.modules.homeManager.nvf
      self.modules.homeManager.nushell
      self.modules.homeManager.opencode
      self.modules.homeManager.typst
    ];
  };

  flake.modules.homeManager.identity-wsl = { lib, pkgs, ... }: {
    home.username = lib.mkDefault userName;
    home.homeDirectory = lib.mkDefault "/home/${userName}";
    home.stateVersion = lib.mkDefault "25.11";
    home.packages = with pkgs; [
      gh
      git
      neovim
      opencode
      starship
    ];
  };
}
