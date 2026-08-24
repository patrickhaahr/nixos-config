# Git/gh for the agent: attributable hermes identity plus the generic
# workflow settings shared with cli/git.nix (no work include, no nvim
# editor, no lfs — hermes has none of those).
_: {
  flake.modules.homeManager.agent-hermes = {
    home.file.".gitignore-global".text = ''
      .env
      .local_secrets
    '';

    programs = {
      git.enable = true;
      gh.enable = true;

      git.settings = {
        user = {
          name = "hermes";
          email = "hermes@haahr.me";
        };
        url = {
          "git@github.com:" = {
            insteadOf = [
              "https://github.com/"
              "gh:"
            ];
          };
          "git@github.com:patrickhaahr/" = {
            insteadOf = [ "ph:" ];
          };
        };
        init.defaultBranch = "master";
        core.excludesfile = "~/.gitignore-global";
        pull.rebase = true;
        alias = {
          st = "status";
          logd = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };
      };
    };
  };
}
