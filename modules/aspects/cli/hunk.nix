{ inputs, ... }: {
  flake.modules.homeManager.hunk = { pkgs, ... }: {
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
    home.file.".agents/skills/hunk-review".source = "${
      inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default
    }/skills/hunk-review";
  };
}
