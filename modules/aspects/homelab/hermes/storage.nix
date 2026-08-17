_: {
  flake.modules.nixos.homelab-hermes-storage = {
    services.k3s.manifests.hermes-storage.content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "hermes";
      }
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "hermes-data";
          namespace = "hermes";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = "20Gi";
        };
      }
    ];
  };
}
