{ ... }: {
  flake.modules.homeManager.direnv = {
    programs.direnv = {
      enable = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
