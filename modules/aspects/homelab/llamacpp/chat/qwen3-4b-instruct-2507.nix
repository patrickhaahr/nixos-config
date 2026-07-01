{ ... }: {
  flake.modules.nixos.homelab-llamacpp-chat-qwen3-4b-instruct-2507 =
    let
      app = "llamacpp-chat-qwen3";
      modelName = "qwen3-4b-instruct-2507";
      modelFile = "Qwen3-4B-Instruct-2507-Q5_K_M.gguf";
    in
    {
      services.k3s.manifests.llamacpp-chat-qwen3.content = [
        {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            name = "${app}-models";
            namespace = "llamacpp";
          };
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            resources.requests.storage = "6Gi";
          };
        }
        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = app;
            namespace = "llamacpp";
            labels.app = app;
          };
          spec = {
            replicas = 1;
            strategy.type = "Recreate";
            selector.matchLabels.app = app;
            template = {
              metadata.labels.app = app;
              spec.runtimeClassName = "nvidia-cdi";
              spec.tolerations = [
                {
                  key = "nvidia.com/gpu";
                  operator = "Exists";
                  effect = "NoSchedule";
                }
              ];
              spec.containers = [
                {
                  name = "server";
                  image = "ghcr.io/ggml-org/llama.cpp:server-cuda";
                  imagePullPolicy = "IfNotPresent";
                  env = [
                    {
                      name = "LLAMA_ARG_HF_REPO";
                      value = "unsloth/Qwen3-4B-Instruct-2507-GGUF";
                    }
                    {
                      name = "LLAMA_ARG_HF_FILE";
                      value = modelFile;
                    }
                    {
                      name = "LLAMA_ARG_ALIAS";
                      value = modelName;
                    }
                    {
                      name = "LLAMA_ARG_HOST";
                      value = "0.0.0.0";
                    }
                    {
                      name = "LLAMA_ARG_PORT";
                      value = "8080";
                    }
                    {
                      name = "LLAMA_ARG_CTX_SIZE";
                      value = "4096";
                    }
                    {
                      name = "LLAMA_ARG_N_GPU_LAYERS";
                      value = "999";
                    }
                    {
                      name = "LLAMA_ARG_ENDPOINT_METRICS";
                      value = "true";
                    }
                  ];
                  ports = [
                    {
                      name = "http";
                      containerPort = 8080;
                    }
                  ];
                  readinessProbe = {
                    httpGet = {
                      path = "/health";
                      port = "http";
                    };
                    periodSeconds = 10;
                    timeoutSeconds = 5;
                    failureThreshold = 6;
                  };
                  startupProbe = {
                    httpGet = {
                      path = "/health";
                      port = "http";
                    };
                    periodSeconds = 10;
                    timeoutSeconds = 5;
                    failureThreshold = 180;
                  };
                  resources = {
                    requests = {
                      cpu = "500m";
                      memory = "4Gi";
                      "nvidia.com/gpu" = "1";
                    };
                    limits = {
                      memory = "12Gi";
                      "nvidia.com/gpu" = "1";
                    };
                  };
                  volumeMounts = [
                    {
                      name = "models";
                      mountPath = "/root/.cache/llama.cpp";
                    }
                  ];
                }
              ];
              spec.volumes = [
                {
                  name = "models";
                  persistentVolumeClaim.claimName = "${app}-models";
                }
              ];
            };
          };
        }
        {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "llamacpp-chat";
            namespace = "llamacpp";
          };
          spec = {
            selector.app = app;
            ports = [
              {
                name = "http";
                port = 8080;
                targetPort = "http";
              }
            ];
          };
        }
      ];
    };
}
