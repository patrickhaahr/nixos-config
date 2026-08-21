_: {
  flake.modules.nixos.homelab-hermes-secrets = {
    sops.secrets = {
      hermes_dashboard_basic_auth_username.owner = "hermes";
      hermes_dashboard_basic_auth_password.owner = "hermes";
      hermes_dashboard_basic_auth_secret.owner = "hermes";
      hermes_api_server_key.owner = "hermes";
      hermes_signal_account.owner = "hermes";
    };
  };
}
