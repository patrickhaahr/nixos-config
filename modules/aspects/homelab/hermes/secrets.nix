_: {
  flake.modules.nixos.homelab-hermes-secrets =
    {
      config,
      hermesRuntime,
      pkgs,
      ...
    }:
    {
      sops.secrets = {
        hermes_dashboard_basic_auth_username = { };
        hermes_dashboard_basic_auth_password = { };
        hermes_dashboard_basic_auth_secret = { };
        hermes_api_server_key = { };
        hermes_signal_account = { };
      };

      systemd.services.k3s-hermes-secrets = {
        description = "Sync Hermes secrets into k3s";
        after = [ "k3s.service" ];
        wants = [ "k3s.service" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathExists = config.sops.secrets.hermes_dashboard_basic_auth_username.path;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [
          pkgs.k3s
          pkgs.gnugrep
        ];
        script = ''
          # K3s applies manifests before it has finished importing services.k3s.images.
          # Keep these local-only init images from falling back to Docker Hub on boot.
          while ! k3s ctr --namespace k8s.io images list --quiet \
            | grep --fixed-strings --quiet 'docker.io/library/hermes-brainrot-plugin:${hermesRuntime.brainrotImageTag}' \
            || ! k3s ctr --namespace k8s.io images list --quiet \
              | grep --fixed-strings --quiet 'docker.io/library/hermes-media-tools:${hermesRuntime.mediaToolsImageTag}'; do
            sleep 1
          done

          k3s kubectl create namespace hermes --dry-run=client --output yaml \
            | k3s kubectl apply --filename -

          k3s kubectl --namespace hermes create secret generic hermes-dashboard-auth \
            --from-file=HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.sops.secrets.hermes_dashboard_basic_auth_username.path} \
            --from-file=HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.secrets.hermes_dashboard_basic_auth_password.path} \
            --from-file=HERMES_DASHBOARD_BASIC_AUTH_SECRET=${config.sops.secrets.hermes_dashboard_basic_auth_secret.path} \
            --dry-run=client \
            --output yaml \
            | k3s kubectl apply --filename -

          k3s kubectl --namespace hermes create secret generic hermes-signal \
            --from-file=SIGNAL_ACCOUNT=${config.sops.secrets.hermes_signal_account.path} \
            --dry-run=client \
            --output yaml \
            | k3s kubectl apply --filename -

          k3s kubectl --namespace hermes create secret generic hermes-api-server \
            --from-file=API_SERVER_KEY=${config.sops.secrets.hermes_api_server_key.path} \
            --dry-run=client \
            --output yaml \
            | k3s kubectl apply --filename -

          if k3s kubectl --namespace hermes get deployment hermes >/dev/null 2>&1; then
            k3s kubectl --namespace hermes scale deployment/hermes --replicas=1
          fi
        '';
      };
    };
}
