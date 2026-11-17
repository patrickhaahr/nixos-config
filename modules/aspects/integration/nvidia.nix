_: {
  # NVIDIA driver plus the container toolkit, whose CDI spec lets podman
  # containers take the GPU (`--device nvidia.com/gpu=all`).
  flake.modules.nixos.nvidia = {
    hardware = {
      graphics.enable = true;
      nvidia = {
        branch = "legacy_580";
        open = false;
        nvidiaPersistenced = true;
      };
      nvidia-container-toolkit.enable = true;
    };
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
