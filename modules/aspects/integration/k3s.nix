{ ... }: {
  flake.modules.nixos.k3s = {
    networking.firewall.trustedInterfaces = [
      "cni0"
      "flannel.1"
    ];

    networking.firewall.allowedTCPPorts = [
      80
      443
      6443
    ];

    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = [ "--node-ip=10.0.20.3" ];
    };
  };
}
