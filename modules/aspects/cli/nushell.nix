_: {
  flake.modules.homeManager.nushell = {
    programs = {
      nushell = {
        enable = true;
        shellAliases = {
          nano = "nvim";
          code = "opencode -c";
          cd = "z";
          c = "clear";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          e = "nautilus .";
        };
        environmentVariables.EDITOR = "nvim";
        extraConfig = ''
          def --env mkcd [dir: string] {
            mkdir $dir
            cd $dir
          }

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
            },
            # These prompt-boundary escape sequences can corrupt Reedline repainting
            # in WSL terminals, causing the prompt line to accumulate padding while typing.
            shell_integration: {
              osc2: true,
              osc7: true,
              osc8: true,
              osc9_9: false,
              osc133: false,
              osc633: false,
              reset_application_mode: true
            }
          }
        '';
      };
      zoxide.enable = true;
      starship = {
        enable = true;
        settings = {
          add_newline = false;
          character = {
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
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
