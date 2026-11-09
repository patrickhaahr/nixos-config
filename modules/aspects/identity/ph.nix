{ self, lib, ... }:
let
  userName = "ph";
in
{
  flake.modules = {
    nixos.identity-ph = { config, pkgs, ... }: {
      users.users.${userName} = {
        isNormalUser = true;
        linger = true;
        description = userName;
        extraGroups = [ "wheel" ];
        shell = pkgs.bashInteractive;
        packages = with pkgs; [ ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFRDoMg0lCDaI7cG3C5wcRtRz2gJXbFYDemOK+KLS5U nika"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWIIdTomMDrLElXLqDg68u7h8Ila5Rjg5TZIngPMUeH ph@loki"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJ80qJZCpCmfiSfRaApMHuGcG3yX9lYLks1oXuBQ4Kt grapheneos"
          # hermes agent outbound key
          (lib.removeSuffix "\n" (builtins.readFile ../../../secrets/hermes/hosts.pub))
        ];
      };
      home-manager.users.${userName}.imports = [
        self.modules.homeManager.identity-ph
      ]
      ++ lib.optional (config.programs.hex.enable or false) self.modules.homeManager.hex;
    };

    nixos.identity-ph-cliproxyapi = {
      home-manager.users.${userName}.imports = [ self.modules.homeManager.cliproxyapi ];
    };

    homeManager.identity-ph = { lib, ... }: {
      programs.bash.initExtra = lib.mkAfter ''
        if [[ $- == *i* && -z ''${BASH_EXECUTION_STRING-} && -z ''${NU_VERSION-} && -t 0 ]]; then
          exec nu
        fi
      '';

      home = {
        username = lib.mkDefault userName;
        homeDirectory = lib.mkDefault "/home/${userName}";
        stateVersion = lib.mkDefault "25.11";
      };
    };
  };
}
