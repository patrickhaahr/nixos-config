{ ... }: {
  flake.modules.homeManager.jj = {
    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "patrickhaahr";
          email = "git@haahr.me";
        };
        revset-aliases."trunk()" = "master@origin";
      };
    };
  };
}
