{ ... }: {
  flake.modules.nixos.homelab-wazuh = { config, pkgs, ... }:
    let
      wazuhKubernetes = pkgs.fetchFromGitHub {
        owner = "wazuh";
        repo = "wazuh-kubernetes";
        rev = "v4.14.5";
        hash = "sha256-HHHUYjVzNuutMOZqO6jl9eGG0abattqssNCSIu4CA30=";
      };
    in {
      sops.secrets = {
        wazuh_api_username = { };
        wazuh_api_password = { };
        wazuh_authd_password = { };
        wazuh_cluster_key = { };
        wazuh_dashboard_username = { };
        wazuh_dashboard_password = { };
        wazuh_indexer_username = { };
        wazuh_indexer_password = { };
      };

      networking.firewall.allowedTCPPorts = [
        1514
        1515
        55000
      ];

      systemd.services.k3s-wazuh = {
        description = "Deploy Wazuh into k3s";
        after = [ "k3s.service" ];
        wants = [ "k3s.service" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathExists = config.sops.secrets.wazuh_api_password.path;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "wazuh-kubernetes";
        };
        path = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.apacheHttpd
          pkgs.gawk
          pkgs.gnused
          pkgs.k3s
          pkgs.kustomize
          pkgs.openssl
          pkgs.rsync
        ];
        script = ''
          set -eu

          workdir=/var/lib/wazuh-kubernetes

          rsync --archive --delete --chmod=u+rwX \
            --exclude '/wazuh/certs/indexer_cluster/*.pem' \
            --exclude '/wazuh/certs/dashboard_http/*.pem' \
            ${wazuhKubernetes}/ "$workdir"/
          cd "$workdir"

          if [ ! -f wazuh/certs/indexer_cluster/root-ca.pem ]; then
            ${pkgs.bash}/bin/bash ./wazuh/certs/indexer_cluster/generate_certs.sh
          fi

          if [ ! -f wazuh/certs/dashboard_http/cert.pem ]; then
            ${pkgs.bash}/bin/bash ./wazuh/certs/dashboard_http/generate_certs.sh
          fi

          secret_literal() {
            tr -d '\n' < "$1"
          }

          validate_wazuh_cluster_key() {
            key="$(secret_literal "$1")"
            if [ "''${#key}" -ne 32 ] || printf '%s' "$key" | grep -q '[^0-9A-Za-z]'; then
              printf '%s\n' \
                'wazuh_cluster_key must be exactly 32 alphanumeric characters.' \
                'Generate one with: openssl rand -base64 24 | tr -dc A-Za-z0-9 | head -c 32' >&2
              exit 1
            fi
          }

          validate_wazuh_cluster_key ${config.sops.secrets.wazuh_cluster_key.path}

          secret_bcrypt_hash() {
            secret_literal "$1" | htpasswd -BinC 12 wazuh-user | cut -d: -f2-
          }

          patch_internal_user_hash() {
            username="$1"
            hash="$2"
            file=wazuh/indexer_stack/wazuh-indexer/indexer_conf/internal_users.yml
            tmp="$file.tmp"

            awk -v username="$username" -v hash="$hash" '
              $0 == username ":" { in_user = 1; print; next }
              in_user && $1 == "hash:" { print "  hash: \"" hash "\""; in_user = 0; next }
              in_user && $0 !~ /^  / { in_user = 0 }
              { print }
            ' "$file" > "$tmp"
            mv "$tmp" "$file"
          }

          patch_internal_user_hash \
            "$(secret_literal ${config.sops.secrets.wazuh_indexer_username.path})" \
            "$(secret_bcrypt_hash ${config.sops.secrets.wazuh_indexer_password.path})"
          patch_internal_user_hash \
            "$(secret_literal ${config.sops.secrets.wazuh_dashboard_username.path})" \
            "$(secret_bcrypt_hash ${config.sops.secrets.wazuh_dashboard_password.path})"

          k3s kubectl create namespace wazuh --dry-run=client --output yaml \
            | k3s kubectl apply --filename -

          k3s kubectl --namespace wazuh create secret generic wazuh-api-cred \
            --from-literal=username="$(secret_literal ${config.sops.secrets.wazuh_api_username.path})" \
            --from-literal=password="$(secret_literal ${config.sops.secrets.wazuh_api_password.path})" \
            --dry-run=client \
            --output yaml \
            | k3s kubectl apply --filename -

          k3s kubectl --namespace wazuh create secret generic wazuh-authd-pass \
            --from-literal=authd.pass="$(secret_literal ${config.sops.secrets.wazuh_authd_password.path})" \
            --dry-run=client \
            --output yaml \
            | k3s kubectl apply --filename -

          k3s kubectl --namespace wazuh create secret generic wazuh-cluster-key \
            --from-literal=key="$(secret_literal ${config.sops.secrets.wazuh_cluster_key.path})" \
            --dry-run=client \
            --output yaml \
            | k3s kubectl apply --filename -

          k3s kubectl --namespace wazuh create secret generic dashboard-cred \
            --from-literal=username="$(secret_literal ${config.sops.secrets.wazuh_dashboard_username.path})" \
            --from-literal=password="$(secret_literal ${config.sops.secrets.wazuh_dashboard_password.path})" \
            --dry-run=client \
            --output yaml \
            | k3s kubectl apply --filename -

          k3s kubectl --namespace wazuh create secret generic indexer-cred \
            --from-literal=username="$(secret_literal ${config.sops.secrets.wazuh_indexer_username.path})" \
            --from-literal=password="$(secret_literal ${config.sops.secrets.wazuh_indexer_password.path})" \
            --dry-run=client \
            --output yaml \
            | k3s kubectl apply --filename -

          sed -i '/secrets\/.*-secret.yaml/d' wazuh/kustomization.yml
          sed -i 's#microk8s.io/hostpath#rancher.io/local-path#' envs/local-env/storage-class.yaml
          if ! grep -q '^volumeBindingMode:' envs/local-env/storage-class.yaml; then
            cat >> envs/local-env/storage-class.yaml <<'EOF'

          volumeBindingMode: WaitForFirstConsumer
          EOF
          fi

          cat > envs/local-env/zaza-ingress-route.yaml <<'EOF'
          apiVersion: traefik.io/v1alpha1
          kind: IngressRoute
          metadata:
            name: wazuh-dashboard
            namespace: wazuh
          spec:
            entryPoints:
              - websecure
            routes:
              - match: Host(`wazuh.zaza.haahr.me`)
                kind: Rule
                services:
                  - name: dashboard
                    port: 443
                    scheme: https
                    serversTransport: wazuh-dashboard
            tls:
              certResolver: cloudflare
          ---
          apiVersion: traefik.io/v1alpha1
          kind: ServersTransport
          metadata:
            name: wazuh-dashboard
            namespace: wazuh
          spec:
            insecureSkipVerify: true
          EOF

          cat > envs/local-env/zaza-service-types.yaml <<'EOF'
          apiVersion: v1
          kind: Service
          metadata:
            name: dashboard
            namespace: wazuh
          spec:
            type: ClusterIP
          ---
          apiVersion: v1
          kind: Service
          metadata:
            name: indexer
            namespace: wazuh
          spec:
            type: ClusterIP
          EOF

          cat > envs/local-env/zaza-dashboard-api-url.yaml <<'EOF'
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: wazuh-dashboard
            namespace: wazuh
          spec:
            template:
              spec:
                containers:
                  - name: wazuh-dashboard
                    env:
                      - name: WAZUH_API_URL
                        value: https://wazuh
          EOF

          cat > envs/local-env/kustomization.yml <<'EOF'
          apiVersion: kustomize.config.k8s.io/v1beta1
          kind: Kustomization
          resources:
            - ../../wazuh
            - zaza-ingress-route.yaml
          patches:
            - path: storage-class.yaml
            - path: indexer-resources.yaml
            - path: wazuh-resources.yaml
            - path: zaza-service-types.yaml
            - path: zaza-dashboard-api-url.yaml
          EOF

          k3s kubectl apply --kustomize envs/local-env
        '';
      };
    };
}
