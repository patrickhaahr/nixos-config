{ self, ... }: {
  flake.modules.nixos.homelab-llamacpp-nika = { lib, ... }: {
    imports = [
      self.modules.nixos.homelab-llamacpp-nika-qwen3-14b
      self.modules.nixos.homelab-llamacpp-nika-qwen3-6-35b-a3b
    ];

    options.services.llamacpp.nika.model = lib.mkOption {
      type = lib.types.enum [ "none" "qwen3-14b" "qwen3-6-35b-a3b" ];
      default = "qwen3-14b";
      description = "The llama.cpp model service to run on nika.";
    };
  };
}
