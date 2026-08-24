# Single seam for hosting hermes on a machine: account + HM runtime stack,
# outbound SSH keys/secrets, and the dev workspace bootstrap. Compose hosts
# import this instead of the individual pieces.
{ self, ... }: {
  flake.modules.nixos.agent-hermes-host.imports = [
    self.modules.nixos.identity-hermes
    self.modules.nixos.agent-hermes-ssh
    self.modules.nixos.agent-hermes-dev-workspace
  ];
}
