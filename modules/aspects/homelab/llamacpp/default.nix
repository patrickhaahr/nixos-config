{ self, ... }: {
  flake.modules.nixos.homelab-llamacpp = {
    imports = [
      self.modules.nixos.homelab-llamacpp-embeddings-nomic-embed-text-v1-5
    ];

    services.k3s.manifests.llamacpp-namespace.content = {
      apiVersion = "v1";
      kind = "Namespace";
      metadata.name = "llamacpp";
    };
  };
}
