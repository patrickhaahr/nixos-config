_: {
  flake.modules.nixos.nix-maintenance = {
    nix = {
      settings = {
        min-free = 5 * 1024 * 1024 * 1024;
        max-free = 10 * 1024 * 1024 * 1024;
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };
    };
  };
}
