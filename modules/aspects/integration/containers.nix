{ ... }: {
  flake.modules.nixos.containers = {
    virtualisation.containers.enable = true;
    virtualisation.podman.enable = true;
    virtualisation.docker.enable = true;
  };
}
