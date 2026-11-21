_: {
  flake.modules.nixos.nix-maintenance = {
    nix = {
      settings = {

        min-free = 20 * 1024 * 1024 * 1024;
        max-free = 50 * 1024 * 1024 * 1024;
      };

      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 7d";
      };

      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };
    };
  };
}
