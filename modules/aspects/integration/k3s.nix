{ ... }: {
  flake.modules.nixos.k3s = {
    networking.firewall.allowedTCPPorts = [
      80
      443
      6443
    ];

    services.k3s = {
      enable = true;
      role = "server";
    };
  };
}
