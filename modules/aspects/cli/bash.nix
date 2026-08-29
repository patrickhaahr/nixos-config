# Interactive Bash with programmable completion.
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

    # Interactive ssh sessions start bash as a login shell, which reads
    # .bash_profile (not .bashrc). HM only writes .bashrc, so bridge it.
    home.file.".bash_profile".text = ''
      [[ -f ~/.bashrc ]] && . ~/.bashrc
    '';
  };
}
