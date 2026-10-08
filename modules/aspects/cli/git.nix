_: {
  flake.modules.homeManager.git = {
    home.file.".gitignore-global".text = ''
      .env
      .local_secrets
    '';

    xdg.configFile."git/config-work".text = ''
      [user]
        email = pqh@timengo.com
    '';

    programs.git = {
      enable = true;
      lfs.enable = true;
      includes = [
        {
          condition = "gitdir:~/dev/work/";
          path = "~/.config/git/config-work";
        }
      ];
      settings = {
        user = {
          name = "patrickhaahr";
          email = "git@haahr.me";
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
        core = {
          editor = "nvim";
          excludesfile = "~/.gitignore-global";
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
