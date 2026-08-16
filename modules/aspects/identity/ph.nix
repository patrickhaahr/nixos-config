{ self, ... }:
let
  userName = "ph";
in
{
  flake.modules.nixos.identity-ph = { pkgs, ... }: {
    users.users.${userName} = {
      isNormalUser = true;
      description = userName;
      extraGroups = [ "wheel" ];
      shell = pkgs.nushell;
      packages = with pkgs; [ ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFRDoMg0lCDaI7cG3C5wcRtRz2gJXbFYDemOK+KLS5U nika"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWIIdTomMDrLElXLqDg68u7h8Ila5Rjg5TZIngPMUeH ph@loki"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBow0SMe+E5nrSuhmq45vcb/CzYEHQsPANx5vGNRksR8 grapheneos"
      ];
    };
    home-manager.users.${userName}.imports = [ self.modules.homeManager.identity-ph ];
  };

  flake.modules.homeManager.identity-ph = { lib, ... }: {
    home = {
      username = lib.mkDefault userName;
      homeDirectory = lib.mkDefault "/home/${userName}";
      stateVersion = lib.mkDefault "25.11";
    };
  };
}
