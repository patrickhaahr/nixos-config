{ ... }: {
  flake.modules.nixos.homelab-llamacpp-nika-qwen3-14b =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.services.llamacpp.nika.model == "qwen3-14b") {
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

      systemd.services.llamacpp-chat = {
        description = "llama.cpp Qwen3 14B chat server";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          HOME = "/var/lib/llamacpp";
          XDG_CACHE_HOME = "/var/cache/llamacpp";
          LLAMA_ARG_HF_REPO = "unsloth/Qwen3-14B-GGUF";
          LLAMA_ARG_HF_FILE = "Qwen3-14B-UD-Q4_K_XL.gguf";
          LLAMA_ARG_ALIAS = "qwen3-14b";
          LLAMA_ARG_HOST = "0.0.0.0";
          LLAMA_ARG_PORT = "8080";
          LLAMA_ARG_CTX_SIZE = "131072";
          LLAMA_ARG_N_GPU_LAYERS = "all";
          LLAMA_ARG_N_PARALLEL = "1";
          LLAMA_ARG_THREADS = "16";
          LLAMA_ARG_THREADS_BATCH = "16";
          LLAMA_ARG_CACHE_TYPE_K = "q8_0";
          LLAMA_ARG_CACHE_TYPE_V = "q8_0";
          LLAMA_ARG_FLASH_ATTN = "on";
          LLAMA_ARG_JINJA = "true";
          LLAMA_ARG_ENDPOINT_METRICS = "true";
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
