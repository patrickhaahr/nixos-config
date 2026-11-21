_: {

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
