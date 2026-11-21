_: {

  flake.modules.nixos.homelab-podman =
    { config, lib, ... }:
    let
      networks = config.homelab.podmanNetworks;
      unit = network: "podman-network-${network}.service";
    in
    {

      key = "homelab-podman";

      options.homelab.podmanNetworks = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        description = "Podman network name to the oci-containers joined to it.";
      };

      config = {

        virtualisation.podman.autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [ "--all" ];
        };

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

                serviceConfig.Type = "oneshot";
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
