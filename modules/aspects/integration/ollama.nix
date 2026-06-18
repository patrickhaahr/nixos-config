{ ... }: {
  flake.modules.nixos.ollama = { pkgs, ... }: {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      host = "0.0.0.0";
      port = 11434;
      loadModels = [ "qwen3.5:9b" ];
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "200000";
        OLLAMA_KEEP_ALIVE = "10m";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 11434 ];
  };
}
