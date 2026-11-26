_: {
  flake.modules.nixos.homelab-vaultwarden =
    { config, ... }:
    {
      services.vaultwarden = {
        enable = true;
        domain = "vault.${config.homelab.domain}";
        configureNginx = true;
        backupDir = "/var/backup/vaultwarden";
        config.SIGNUPS_ALLOWED = false;
      };
    };
}
