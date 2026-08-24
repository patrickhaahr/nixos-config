{ inputs, ... }: {
  flake.modules.nixos.agent-hermes-ssh =
    { pkgs, ... }:
    let
      sshConfig = pkgs.writeText "hermes-ssh-config" ''
        Host github.com
          User git
          IdentityFile ~/.ssh/id_ed25519_hermes_git
          IdentitiesOnly yes
          StrictHostKeyChecking accept-new

        Host uranus
          HostName 100.118.180.74
          User root
          IdentityFile ~/.ssh/id_ed25519_hermes_hosts
          IdentitiesOnly yes
          StrictHostKeyChecking accept-new

        Host zaza *
          IdentityFile ~/.ssh/id_ed25519_hermes_hosts
          IdentitiesOnly yes
          StrictHostKeyChecking accept-new
      '';
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        # Per-secret sopsFile instead of defaultSopsFile: hosts like zaza
        # already set a host-wide default we must not override.
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets = {
          hermes_git_key = {
            sopsFile = ../../../../secrets/hermes/ssh.yaml;
            path = "/home/hermes/.ssh/id_ed25519_hermes_git";
            owner = "hermes";
          };
          hermes_hosts_key = {
            sopsFile = ../../../../secrets/hermes/ssh.yaml;
            path = "/home/hermes/.ssh/id_ed25519_hermes_hosts";
            owner = "hermes";
          };
          # Bootstrap key for hermes's HM sops module: rendered to the exact
          # path it expects so agent secrets decrypt without manual placement.
          hermes_age_key = {
            sopsFile = ../../../../secrets/hermes/ssh.yaml;
            path = "/home/hermes/.config/sops/age/keys.txt";
            owner = "hermes";
            mode = "0600";
          };
        };
      };

      # Declarative ssh client config: pins each destination to its key so
      # hermes can never fall back to ph's keys.
      systemd.tmpfiles.rules = [
        "d /home/hermes/.ssh 0700 hermes users -"
        "L+ /home/hermes/.ssh/config - - - - ${sshConfig}"
      ];
    };
}
