{ self, ... }: {
  flake.modules.nixos.homelab-llamacpp = {
    imports = [
      self.modules.nixos.homelab-llamacpp-chat-qwen3-4b-instruct-2507
      self.modules.nixos.homelab-llamacpp-embeddings-nomic-embed-text-v1-5
      self.modules.nixos.homelab-llamacpp-nika-ingress
    ];

    services.k3s.manifests.llamacpp-namespace.content = {
      apiVersion = "v1";
      kind = "Namespace";
      metadata.name = "llamacpp";
    };
  };
}
