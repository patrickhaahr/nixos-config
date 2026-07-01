{ ... }: {
  flake.modules.nixos.homelab-llamacpp-embeddings-nomic-embed-text-v1-5 =
    let
      app = "llamacpp-embeddings-nomic";
      modelName = "nomic-embed-text-v1.5";
      modelFile = "nomic-embed-text-v1.5.f16.gguf";
    in
    {
      services.k3s.manifests.llamacpp-embeddings-nomic.content = [
        {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            name = "${app}-models";
            namespace = "llamacpp";
          };
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            resources.requests.storage = "4Gi";
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
              spec.containers = [
                {
                  name = "server";
                  image = "ghcr.io/ggml-org/llama.cpp:server";
                  imagePullPolicy = "IfNotPresent";
                  env = [
                    {
                      name = "LLAMA_ARG_HF_REPO";
                      value = "nomic-ai/nomic-embed-text-v1.5-GGUF";
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
                      name = "LLAMA_ARG_EMBEDDINGS";
                      value = "true";
                    }
                    {
                      name = "LLAMA_ARG_POOLING";
                      value = "mean";
                    }
                    {
                      name = "LLAMA_ARG_CTX_SIZE";
                      value = "8192";
                    }
                    {
                      name = "LLAMA_ARG_BATCH";
                      value = "8192";
                    }
                    {
                      name = "LLAMA_ARG_ROPE_SCALING_TYPE";
                      value = "yarn";
                    }
                    {
                      name = "LLAMA_ARG_ROPE_FREQ_SCALE";
                      value = "0.75";
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
                    failureThreshold = 120;
                  };
                  resources = {
                    requests = {
                      cpu = "500m";
                      memory = "2Gi";
                    };
                    limits.memory = "6Gi";
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
            name = "llamacpp-embeddings";
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
