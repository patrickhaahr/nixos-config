{ inputs, ... }: {
  flake.modules.homeManager.hunk = {
    imports = [ inputs.hunk.homeManagerModules.default ];
    programs.hunk = {
      enable = true;
      enableGitIntegration = true;
      settings = {
        theme = "catppuccin-mocha";
        line_numbers = true;
        tab_width = 4;
      };
    };
  };
}
