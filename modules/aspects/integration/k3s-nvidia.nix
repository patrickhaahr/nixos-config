{ ... }: {
  flake.modules.nixos.k3s-nvidia = { pkgs, ... }: {
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      branch = "legacy_580";
      open = false;
      nvidiaPersistenced = true;
    };
    hardware.nvidia-container-toolkit.enable = true;

    # Put nvidia-container-runtime on k3s's PATH so k3s auto-detects it and
    # wires the containerd "nvidia"/"nvidia-cdi" runtimes. On NixOS the legacy
    # "nvidia" runtime is broken (it emits an FHS /usr/bin/nvidia-ctk hook), so
    # GPU workloads use the CDI runtime, which consumes the CDI spec generated
    # by hardware.nvidia-container-toolkit (correct /nix/store paths).
    systemd.services.k3s.path = [ pkgs.nvidia-container-toolkit.tools ];

    services.k3s.manifests.nvidia-device-plugin.content = [
      {
        apiVersion = "node.k8s.io/v1";
        kind = "RuntimeClass";
        metadata.name = "nvidia-cdi";
        handler = "nvidia-cdi";
      }
      {
        apiVersion = "apps/v1";
        kind = "DaemonSet";
        metadata = {
          name = "nvidia-device-plugin-daemonset";
          namespace = "kube-system";
        };
        spec = {
          selector.matchLabels.name = "nvidia-device-plugin-ds";
          updateStrategy.type = "RollingUpdate";
          template = {
            metadata.labels.name = "nvidia-device-plugin-ds";
            spec = {
              runtimeClassName = "nvidia-cdi";
              tolerations = [
                {
                  key = "nvidia.com/gpu";
                  operator = "Exists";
                  effect = "NoSchedule";
                }
              ];
              priorityClassName = "system-node-critical";
              containers = [
                {
                  name = "nvidia-device-plugin-ctr";
                  image = "nvcr.io/nvidia/k8s-device-plugin:v0.17.1";
                  env = [
                    {
                      name = "NVIDIA_VISIBLE_DEVICES";
                      value = "all";
                    }
                    {
                      name = "NVIDIA_DRIVER_CAPABILITIES";
                      value = "all";
                    }
                    {
                      name = "DEVICE_LIST_STRATEGY";
                      value = "envvar";
                    }
                    # CDI spec names GPUs by index (0/all), not UUID, so the
                    # plugin must allocate by index for the CDI runtime to
                    # resolve nvidia.com/gpu=0.
                    {
                      name = "DEVICE_ID_STRATEGY";
                      value = "index";
                    }
                    {
                      name = "FAIL_ON_INIT_ERROR";
                      value = "true";
                    }
                  ];
                  securityContext = {
                    allowPrivilegeEscalation = false;
                    capabilities.drop = [ "ALL" ];
                  };
                  volumeMounts = [
                    {
                      name = "device-plugin";
                      mountPath = "/var/lib/kubelet/device-plugins";
                    }
                  ];
                }
              ];
              volumes = [
                {
                  name = "device-plugin";
                  hostPath.path = "/var/lib/kubelet/device-plugins";
                }
              ];
            };
          };
        };
      }
    ];
  };
}
