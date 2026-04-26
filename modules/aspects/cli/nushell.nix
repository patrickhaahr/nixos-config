{ ... }: {
  flake.modules.homeManager.nushell = {
    programs = {
      nushell = {
        enable = true;
        shellAliases = {
          vi = "nvim";
          vim = "nvim";
          nano = "nvim";
          code = "opencode";
          cd = "z";
          c = "clear";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          e = "nautilus .";
        };
        environmentVariables.EDITOR = "nvim";
        extraConfig = ''
          starship init nu | save -f ~/.cache/starship/init.nu
          mkdir ~/.cache/starship
          $env.STARSHIP_CONFIG = "~/.config/starship.toml"
          mkdir ~/.cache/zoxide
          zoxide init nushell | save -f ~/.cache/zoxide/init.nu
          $env.config = {
            show_banner: false,
            completions: {
              case_sensitive: false,
              quick: true,
              partial: true,
              algorithm: "fuzzy",
              external: {
                enable: true,
                max_results: 100
              }
            }
          }
        '';
      };
      zoxide.enable = true;
      starship = {
        enable = true;
        settings = {
          add_newline = true;
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
          };
        };
      };
      carapace = {
        enable = true;
        enableNushellIntegration = true;
      };
    };
  };
}
