_: {
  flake.modules.nixos.k3s =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      manifestDir = "/var/lib/rancher/k3s/server/manifests";

      # Symlinks declared by `services.k3s.manifests` for the current
      # generation, extracted from the k3s module's tmpfiles rules:
      # one "<path><TAB><target>" line per declared manifest.
      declaredManifests =
        let
          rules = config.systemd.tmpfiles.settings."10-k3s" or { };
        in
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            path: types:
            let
              link = types."L+" or null;
            in
            lib.optionalString (
              link != null && link.argument or null != null && lib.hasPrefix "${manifestDir}/" path
            ) "${path}\t${link.argument}"
          ) rules
        );

      manifestList = pkgs.writeText "k3s-declared-manifests" declaredManifests;

      # k3s' deploy controller stats every file in the manifests dir and aborts
      # the whole apply batch on the first error, so a single dangling symlink
      # (leftover from a disabled aspect whose store path got GC'd) blocks ALL
      # manifest applies. The module's tmpfiles `L+` rules only create links,
      # never remove retired ones. Run on every activation to:
      #   - re-link declared manifests whose symlink drifted (store path changed)
      #   - remove any symlink that is dangling or no longer declared
      # Regular files and subdirs k3s ships itself (ccm.yaml, coredns.yaml,
      # metrics-server/...) are not symlinks and are left untouched.
      pruneScript = pkgs.writeShellScript "k3s-manifest-prune" ''
        list=${manifestList}
        first=$(head -n1 "$list" | cut -f1)
        [ -n "$first" ] || exit 0
        dir=$(dirname "$first")

        # Re-sync declared symlinks (skip and unlink if the store target is gone).
        while IFS=$'\t' read -r path target; do
          [ -n "''${path:-}" ] || continue
          if [ ! -e "$target" ]; then
            echo "k3s-manifest-prune: declared target missing, unlinking $path" >&2
            rm -f -- "$path"
          elif [ "$(readlink -- "$path" 2>/dev/null)" != "$target" ]; then
            mkdir -p -- "$(dirname -- "$path")"
            ln -sfn -- "$target" "$path"
          fi
        done < "$list"

        # Drop symlinks that are no longer declared (dangling leftovers).
        for f in "$dir"/*; do
          [ -L "$f" ] || continue
          if ! cut -f1 "$list" | grep -Fqx -- "$f"; then
            rm -f -- "$f"
            echo "k3s-manifest-prune: removed undeclared symlink $f" >&2
          fi
        done
      '';
    in
    {
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

      system.activationScripts.k3sManifestPrune = lib.stringAfter [ "etc" ] "${pruneScript}";
    };
}
