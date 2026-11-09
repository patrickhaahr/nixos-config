{ self, ... }:
{
  flake.modules.homeManager.agent-shell =
    { config, pkgs, ... }:
    let
      direnv = "${config.programs.direnv.package}/bin/direnv";
      bashEnv = pkgs.writeText "agent-bash-env" ''
        if [[ -z ''${__AGENT_BASH_ENV-} ]]; then
          eval "$(__AGENT_BASH_ENV=1 DIRENV_LOG_FORMAT= ${direnv} export bash 2>/dev/null)"
        fi
      '';
    in
    {
      imports = [ self.modules.homeManager.direnv ];

      home.sessionVariables.BASH_ENV = "${bashEnv}";
      systemd.user.sessionVariables.BASH_ENV = "${bashEnv}";

      programs.direnv.config.whitelist.prefix = [ "${config.home.homeDirectory}/.t3/worktrees" ];
    };
}
