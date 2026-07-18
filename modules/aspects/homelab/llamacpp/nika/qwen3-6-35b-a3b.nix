{ ... }: {
  flake.modules.nixos.homelab-llamacpp-nika-qwen3-6-35b-a3b =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.services.llamacpp.nika.model == "qwen3-6-35b-a3b") {
      hardware.graphics.enable = true;

      users.groups.llamacpp = { };
      users.users.llamacpp = {
        isSystemUser = true;
        group = "llamacpp";
        extraGroups = [
          "render"
          "video"
        ];
        home = "/var/lib/llamacpp";
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8080 ];

      environment.systemPackages = [ pkgs.llama-cpp-rocm ];

      systemd.services.llamacpp-qwen3-6-35b-a3b = {
        description = "llama.cpp Qwen3.6 35B-A3B chat server";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        environment = {
          HOME = "/var/lib/llamacpp";
          XDG_CACHE_HOME = "/var/cache/llamacpp";
          LLAMA_ARG_HF_REPO = "unsloth/Qwen3.6-35B-A3B-GGUF";
          LLAMA_ARG_HF_FILE = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
          LLAMA_ARG_ALIAS = "qwen3.6-35b-a3b";
          LLAMA_ARG_HOST = "0.0.0.0";
          LLAMA_ARG_PORT = "8080";
          LLAMA_ARG_CTX_SIZE = "131072";
          LLAMA_ARG_FIT = "on";
          LLAMA_ARG_FIT_CTX = "131072";
          LLAMA_ARG_FIT_TARGET = "1024";
          LLAMA_ARG_MMPROJ_AUTO = "false";
          LLAMA_ARG_N_PARALLEL = "1";
          LLAMA_ARG_BATCH = "1024";
          LLAMA_ARG_UBATCH = "512";
          LLAMA_ARG_THREADS = "16";
          LLAMA_ARG_THREADS_BATCH = "16";
          LLAMA_ARG_CACHE_TYPE_K = "q8_0";
          LLAMA_ARG_CACHE_TYPE_V = "q8_0";
          LLAMA_ARG_FLASH_ATTN = "on";
          LLAMA_ARG_JINJA = "true";
          LLAMA_ARG_MMAP = "false";
          LLAMA_ARG_MLOCK = "true";
          LLAMA_ARG_ENDPOINT_METRICS = "true";
          LLAMA_ARG_LOG_TIMESTAMPS = "true";
          LLAMA_ARG_LOG_VERBOSITY = "4";
        };

        serviceConfig = {
          User = "llamacpp";
          Group = "llamacpp";
          SupplementaryGroups = [
            "render"
            "video"
          ];
          StateDirectory = "llamacpp";
          CacheDirectory = "llamacpp";
          ExecStart = "${pkgs.llama-cpp-rocm}/bin/llama-server --no-ui";
          Restart = "on-failure";
          RestartSec = "5s";
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    };
}
