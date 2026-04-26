{ ... }: {
  flake.modules.homeManager.git = {
    home.file.".gitignore-global".text = ''
      .env
      .local_secrets
    '';

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "patrickhaahr";
          email = "git@haahr.me";
        };
        url = {
          "git@github.com:" = {
            insteadOf = [ "https://github.com/" "gh:" ];
          };
          "git@github.com:patrickhaahr/" = {
            insteadOf = [ "ph:" ];
          };
        };
        init.defaultBranch = "master";
        core = {
          editor = "nvim";
          excludesfile = "~/.gitignore-global";
        };
        filter.lfs = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
        pull.rebase = true;
        alias = {
          st = "status";
          logd = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };
      };
    };
  };
}
