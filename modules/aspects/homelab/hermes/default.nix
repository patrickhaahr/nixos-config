{ self, ... }: {
  flake.modules.nixos.homelab-hermes = {
    imports = [
      self.modules.nixos.homelab-hermes-user
      self.modules.nixos.homelab-hermes-secrets
      self.modules.nixos.homelab-hermes-provision
      self.modules.nixos.homelab-hermes-signal-cli
      self.modules.nixos.homelab-hermes-agents
      self.modules.nixos.homelab-hermes-networking
    ];
  };
}
