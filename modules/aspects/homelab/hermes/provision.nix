_: {
  flake.modules.nixos.homelab-hermes-provision =
    { config, pkgs, ... }:
    {
      systemd.services.hermes-provision = {
        description = "Provision Hermes agent runtime state";
        after = [ "sops-nix.service" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathExists = config.sops.secrets.hermes_signal_account.path;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [ pkgs.coreutils ];
        script = ''
          umask 077

          install -d -m 700 -o hermes -g hermes /home/hermes/.hermes/plugins

          if [ ! -e /home/hermes/.hermes/plugins/brainrot-summarizer ]; then
            cp -a ${./plugins/brainrot-summarizer} /home/hermes/.hermes/plugins/brainrot-summarizer
            chown -R hermes:hermes /home/hermes/.hermes/plugins/brainrot-summarizer
          fi

          signal_account="$(tr -d "\r\n" < ${config.sops.secrets.hermes_signal_account.path})"
          api_key="$(tr -d "\r\n" < ${config.sops.secrets.hermes_api_server_key.path})"
          dash_user="$(tr -d "\r\n" < ${config.sops.secrets.hermes_dashboard_basic_auth_username.path})"
          dash_pass="$(tr -d "\r\n" < ${config.sops.secrets.hermes_dashboard_basic_auth_password.path})"
          dash_secret="$(tr -d "\r\n" < ${config.sops.secrets.hermes_dashboard_basic_auth_secret.path})"

          {
            printf 'SIGNAL_ACCOUNT=%s\n' "$signal_account"
            printf 'SIGNAL_ALLOWED_USERS=%s\n' "$signal_account"
            printf 'API_SERVER_KEY=%s\n' "$api_key"
            printf 'HERMES_DASHBOARD_BASIC_AUTH_USERNAME=%s\n' "$dash_user"
            printf 'HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=%s\n' "$dash_pass"
            printf 'HERMES_DASHBOARD_BASIC_AUTH_SECRET=%s\n' "$dash_secret"
          } > /home/hermes/secrets.env

          chown hermes:hermes /home/hermes/secrets.env
          chmod 600 /home/hermes/secrets.env
        '';
      };
    };
}
