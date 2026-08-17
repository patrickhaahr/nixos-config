_: {
  flake.modules.nixos.homelab-hermes-signal-cli = {
    _module.args.hermesSignalCli = {
      initContainers = [
        {
          name = "signal-cli-data-permissions";
          image = "registry.gitlab.com/packaging/signal-cli/signal-cli-native:latest";
          command = [ "chown" ];
          args = [
            "-R"
            "signal-cli:signal-cli"
            "/var/lib/signal-cli"
          ];
          securityContext.runAsUser = 0;
          volumeMounts = [
            {
              name = "signal-cli-data";
              mountPath = "/var/lib/signal-cli";
            }
          ];
        }
      ];
      containers = [
        {
          name = "signal-cli";
          image = "registry.gitlab.com/packaging/signal-cli/signal-cli-native:latest";
          args = [
            "daemon"
            "--http"
            "127.0.0.1:8080"
          ];
          ports = [
            {
              name = "signal-cli";
              containerPort = 8080;
            }
          ];
          volumeMounts = [
            {
              name = "data";
              mountPath = "/opt/data";
            }
            {
              name = "signal-cli-data";
              mountPath = "/var/lib/signal-cli";
            }
            {
              name = "shared-tmp";
              mountPath = "/tmp";
            }
          ];
        }
      ];
      volumes = [
        {
          name = "signal-cli-data";
          persistentVolumeClaim.claimName = "signal-cli-data";
        }
      ];
    };

    services.k3s.manifests.hermes-signal-cli.content = {
      apiVersion = "v1";
      kind = "PersistentVolumeClaim";
      metadata = {
        name = "signal-cli-data";
        namespace = "hermes";
      };
      spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "2Gi";
      };
    };
  };
}
