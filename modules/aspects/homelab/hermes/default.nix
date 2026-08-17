{ self, ... }: {
  flake.modules.nixos.homelab-hermes = {
    imports = [
      self.modules.nixos.homelab-hermes-runtime
      self.modules.nixos.homelab-hermes-secrets
      self.modules.nixos.homelab-hermes-storage
      self.modules.nixos.homelab-hermes-bootstrap
      self.modules.nixos.homelab-hermes-signal-cli
      self.modules.nixos.homelab-hermes-deployment
      self.modules.nixos.homelab-hermes-networking
    ];
  };
}
