{ self, ... }:
{
  flake.modules.homeManager.agent-shell =
    { config, ... }:
    let
      direnv = "${config.programs.direnv.package}/bin/direnv";
      # A fixed path, not a store path: GUI sessions snapshot their environment at
      # login, so the variable must never change; switches only rewrite the file.
      bashEnv = "${config.xdg.configHome}/agent-shell/bash-env";
    in
    {
      imports = [ self.modules.homeManager.direnv ];

      xdg.configFile."agent-shell/bash-env".text = ''
        if [[ -z ''${__AGENT_BASH_ENV-} ]]; then
          eval "$(__AGENT_BASH_ENV=1 DIRENV_LOG_FORMAT= ${direnv} export bash 2>/dev/null)"
        fi
      '';

      home.sessionVariables.BASH_ENV = bashEnv;
      systemd.user.sessionVariables.BASH_ENV = bashEnv;

      programs.direnv.config.whitelist.prefix = [ "${config.home.homeDirectory}/.t3/worktrees" ];
    };
}
