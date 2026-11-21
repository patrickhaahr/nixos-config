# Homelab containers and their lifecycle

Software nixpkgs lacks runs as podman containers, whose lifecycle needs more than `virtualisation.oci-containers` provides.

- `oci-containers` joins containers to a network but never creates one, so `homelab-podman` creates each network as a unit with no `RemainAfterExit`: auto-prune can delete a network while its containers are down, so every container start re-checks it. The module carries a `key` because several homelab aspects import it and the key deduplicates it.
- Weekly auto-prune runs with `--all`, because digest bumps leave the previous image behind; it drops every image no container uses and leaves volumes untouched.
- `wazuh-setup` generates certificates only when none exist and rewrites `internal_users.yml` on every start, but the indexer reads that file only when it first creates its security index, so changing a password later needs `securityadmin.sh` inside the indexer.
- Wazuh manager config is mounted under `/wazuh-config-mount`, not its final path, because the manager entrypoint copies that directory over `/var/ossec`.
- zaza's `nvidia` aspect enables the NVIDIA container toolkit, because its CDI spec is what lets a container take the GPU (`--device nvidia.com/gpu=all`).
