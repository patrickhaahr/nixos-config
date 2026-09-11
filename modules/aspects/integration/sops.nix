{ inputs, ... }: {
  flake.modules.nixos.sops = { config, ... }: {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops = {
      defaultSopsFile = ../../../secrets/zaza.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      # The nix-daemon does the GitHub fetching for flake updates; without a
      # token it hits the 60 req/hr anonymous rate limit. The value is a full
      # `NIX_CONFIG=access-tokens=...` line (kept out of the store via sops).
      secrets.nix_daemon_github_env = { };
    };
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
      config.sops.secrets.nix_daemon_github_env.path;
  };
}
