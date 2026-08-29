_: {
  flake.modules.homeManager.direnv = {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
