_: {
  flake.modules.nixos.containers = {
    virtualisation = {
      containers.enable = true;
      podman.enable = true;
      docker.enable = true;
    };
  };
}
