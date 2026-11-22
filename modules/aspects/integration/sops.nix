{ self, inputs, ... }:
{
  flake.modules.nixos = {
    sops =
      { config, ... }:
      {
        key = "sops";
        imports = [ inputs.sops-nix.nixosModules.sops ];

        sops = {
          defaultSopsFile = ../../../secrets/${config.networking.hostName}.yaml;
          age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
      };

    nix-github-token =
      { config, ... }:
      {
        imports = [ self.modules.nixos.sops ];

        sops.secrets.nix_daemon_github_env = { };
        systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
          config.sops.secrets.nix_daemon_github_env.path;
      };
  };
}
