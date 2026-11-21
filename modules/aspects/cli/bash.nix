_: {
  flake.modules.homeManager.bash = {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      historySize = 10000;
      historyFileSize = 100000;
      historyControl = [
        "ignorespace"
        "ignoredups"
      ];
      shellOptions = [
        "histappend"
        "checkwinsize"
        "cmdhist"
        "globstar"
      ];
      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
      };
    };

    home.file.".bash_profile".text = ''
      [[ -f ~/.bashrc ]] && . ~/.bashrc
    '';
  };
}
