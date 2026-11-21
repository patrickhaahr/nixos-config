{ inputs, ... }: {
  flake.modules.nixos.sops = { config, ... }: {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops = {
      defaultSopsFile = ../../../secrets/zaza.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      secrets.nix_daemon_github_env = { };
    };
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
      config.sops.secrets.nix_daemon_github_env.path;
  };
}
