_: {
  flake.modules.nixos.k3s = {
    users = {
      groups.k3s-admin = { };
      users.ph.extraGroups = [ "k3s-admin" ];
      users.hermes.extraGroups = [ "k3s-admin" ];
    };

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
      extraFlags = [
        "--node-ip=10.0.10.3"
        "--write-kubeconfig-group=k3s-admin"
        "--write-kubeconfig-mode=0640"
      ];
    };
  };
}
