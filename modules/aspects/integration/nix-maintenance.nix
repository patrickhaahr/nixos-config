_: {
  flake.modules.nixos.nix-maintenance = {
    nix = {
      settings = {
        # Builds GC inline once free space drops below min-free, so a burst of
        # builds between scheduled runs cannot fill the disk.
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
