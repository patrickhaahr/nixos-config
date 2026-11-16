_: {
  # Podman networks for `virtualisation.oci-containers`, which joins
  # containers to a network but never creates one. Containers on a network
  # reach each other by name and `--network-alias`.
  flake.modules.nixos.homelab-podman =
    { config, lib, ... }:
    let
      networks = config.homelab.podmanNetworks;
      unit = network: "podman-network-${network}.service";
    in
    {
      # Imported by several homelab aspects; the key deduplicates it.
      key = "homelab-podman";

      options.homelab.podmanNetworks = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        description = "Podman network name to the oci-containers joined to it.";
      };

      config = {
        virtualisation.oci-containers.containers = lib.mkMerge (
          lib.mapAttrsToList (
            network: names:
            lib.genAttrs names (_: {
              networks = [ network ];
            })
          ) networks
        );

        systemd.services = lib.mkMerge (
          lib.mapAttrsToList (
            network: names:
            {
              "podman-network-${network}" = {
                description = "Podman network ${network}";
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };
                path = [ config.virtualisation.podman.package ];
                script = "podman network exists ${network} || podman network create ${network}";
              };
            }
            // lib.genAttrs (map (name: "podman-${name}") names) (_: {
              requires = [ (unit network) ];
              after = [ (unit network) ];
            })
          ) networks
        );
      };
    };
}
