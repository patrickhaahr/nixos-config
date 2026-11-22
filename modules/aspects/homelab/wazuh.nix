{ self, ... }:
{

  flake.modules.nixos.homelab-wazuh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let

      version = "4.14.10";
      upstream = pkgs.fetchFromGitHub {
        owner = "wazuh";
        repo = "wazuh-docker";
        rev = "v${version}";
        hash = "sha256-dC65ldz6N5AQgrcyKq/ujhlb+t3LjvyJdZoWeqhuF1Y=";
      };
      single = "${upstream}/single-node/config";

      stateDir = "/var/lib/wazuh";
      certs = "${stateDir}/certs";
      dashboardPort = 5601;
      secret = name: config.sops.placeholder."wazuh_${name}";

      managerConf = pkgs.writeText "ossec.conf" (
        builtins.replaceStrings [ "<use_password>no</use_password>" ] [ "<use_password>yes</use_password>" ]
          (builtins.readFile "${single}/wazuh_cluster/wazuh_manager.conf")
      );

      dashboardConf = pkgs.writeText "opensearch_dashboards.yml" ''
        server.host: 0.0.0.0
        server.port: ${toString dashboardPort}
        opensearch.hosts: https://wazuh.indexer:9200
        opensearch.ssl.verificationMode: certificate
        opensearch.ssl.certificateAuthorities: ["/usr/share/wazuh-dashboard/certs/root-ca.pem"]
        opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]
        opensearch_security.multitenancy.enabled: false
        opensearch_security.readonly_mode.roles: ["kibana_read_only"]
        server.ssl.enabled: false
        uiSettings.overrides.defaultRoute: /app/wz-home
      '';

      common = {
        environmentFiles = [ config.sops.templates."wazuh.env".path ];
        dependsOn = [ "wazuh-indexer" ];
      };

      containers = {
        wazuh-indexer = {
          image = "docker.io/wazuh/wazuh-indexer:4.14.10@sha256:1d2aeadb9de88c6d17ce12030606425deca5a210cdf5c87008843da38eb629ea";
          environment.OPENSEARCH_JAVA_OPTS = "-Xms1g -Xmx1g";
          volumes =
            let
              dir = "/usr/share/wazuh-indexer/config";
            in
            [
              "wazuh-indexer-data:/var/lib/wazuh-indexer"
              "${certs}/root-ca.pem:${dir}/certs/root-ca.pem:ro"
              "${certs}/wazuh.indexer-key.pem:${dir}/certs/wazuh.indexer.key:ro"
              "${certs}/wazuh.indexer.pem:${dir}/certs/wazuh.indexer.pem:ro"
              "${certs}/admin.pem:${dir}/certs/admin.pem:ro"
              "${certs}/admin-key.pem:${dir}/certs/admin-key.pem:ro"
              "${single}/wazuh_indexer/wazuh.indexer.yml:${dir}/opensearch.yml:ro"
              "${stateDir}/internal_users.yml:${dir}/opensearch-security/internal_users.yml:ro"
            ];
          extraOptions = [
            "--hostname=wazuh.indexer"
            "--network-alias=wazuh.indexer"
          ];
        };

        wazuh-manager = common // {
          image = "docker.io/wazuh/wazuh-manager:4.14.10@sha256:eabfa7ee4e63acb51c2130fa0583e30f843d030b091cf45a4fbd93d78fa21517";
          ports = [
            "1514:1514"
            "1515:1515"
          ];
          environment = {
            INDEXER_URL = "https://wazuh.indexer:9200";
            FILEBEAT_SSL_VERIFICATION_MODE = "full";
            SSL_CERTIFICATE_AUTHORITIES = "/etc/ssl/root-ca.pem";
            SSL_CERTIFICATE = "/etc/ssl/filebeat.pem";
            SSL_KEY = "/etc/ssl/filebeat.key";
          };
          volumes =
            map (dir: "wazuh-${baseNameOf dir}:${dir}") [
              "/var/ossec/api/configuration"
              "/var/ossec/etc"
              "/var/ossec/logs"
              "/var/ossec/queue"
              "/var/ossec/var/multigroups"
              "/var/ossec/integrations"
              "/var/ossec/active-response/bin"
              "/var/ossec/agentless"
              "/var/ossec/wodles"
            ]
            ++ [
              "wazuh-filebeat-etc:/etc/filebeat"
              "wazuh-filebeat-var:/var/lib/filebeat"
              "${certs}/root-ca-manager.pem:/etc/ssl/root-ca.pem:ro"
              "${certs}/wazuh.manager.pem:/etc/ssl/filebeat.pem:ro"
              "${certs}/wazuh.manager-key.pem:/etc/ssl/filebeat.key:ro"

              "${managerConf}:/wazuh-config-mount/etc/ossec.conf:ro"
              "${config.sops.secrets.wazuh_authd_password.path}:/wazuh-config-mount/etc/authd.pass:ro"
            ];
          extraOptions = [
            "--hostname=wazuh.manager"
            "--network-alias=wazuh.manager"
          ];
        };

        wazuh-dashboard = common // {
          image = "docker.io/wazuh/wazuh-dashboard:4.14.10@sha256:4d48be7210a291c00a2bd148cbd8bd61a25876e947b81790fd03f7d2aabda95a";
          dependsOn = [
            "wazuh-indexer"
            "wazuh-manager"
          ];
          ports = [ "127.0.0.1:${toString dashboardPort}:${toString dashboardPort}" ];
          environment.WAZUH_API_URL = "https://wazuh.manager";
          volumes = [
            "${certs}/root-ca.pem:/usr/share/wazuh-dashboard/certs/root-ca.pem:ro"
            "${dashboardConf}:/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml:ro"
            "wazuh-dashboard-config:/usr/share/wazuh-dashboard/data/wazuh/config"
            "wazuh-dashboard-custom:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom"
          ];
          extraOptions = [
            "--hostname=wazuh.dashboard"
            "--network-alias=wazuh.dashboard"
          ];
        };
      };
    in
    {
      imports = [ self.modules.nixos.homelab-podman ];

      sops.secrets = {
        wazuh_api_username = { };
        wazuh_api_password = { };
        wazuh_authd_password = { };
        wazuh_dashboard_username = { };
        wazuh_dashboard_password = { };
        wazuh_indexer_username = { };
        wazuh_indexer_password = { };
      };
      sops.templates."wazuh.env".content = ''
        INDEXER_USERNAME=${secret "indexer_username"}
        INDEXER_PASSWORD=${secret "indexer_password"}
        DASHBOARD_USERNAME=${secret "dashboard_username"}
        DASHBOARD_PASSWORD=${secret "dashboard_password"}
        API_USERNAME=${secret "api_username"}
        API_PASSWORD=${secret "api_password"}
      '';

      virtualisation.oci-containers.containers = containers;
      homelab.podmanNetworks.wazuh = builtins.attrNames containers;

      systemd.services = {
        wazuh-setup = {
          description = "Wazuh certificates and indexer users";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            StateDirectory = "wazuh";
          };
          path = [
            config.virtualisation.podman.package
            pkgs.apacheHttpd
            pkgs.coreutils
          ];
          script =
            let
              path = name: config.sops.secrets."wazuh_${name}".path;
            in
            ''
              set -eu
              if [ ! -e ${certs}/root-ca.pem ]; then
                mkdir -p ${certs}
                podman run --rm \
                  -e CERT_TOOL_VERSION=${lib.versions.majorMinor version} \
                  -v ${certs}:/certificates \
                  -v ${single}/certs.yml:/config/certs.yml:ro \
                  docker.io/wazuh/wazuh-certs-generator:0.0.5@sha256:1be9f9abfb6a37ac7bd3d6d707e1b43589c2b81b23c01a46992e93832795abf9
              fi

              bcrypt() { tr -d '\n' < "$1" | htpasswd -BinC 12 user | cut -d: -f2-; }
              umask 077
              cat > ${stateDir}/internal_users.yml <<EOF
              _meta:
                type: "internalusers"
                config_version: 2
              $(cat ${path "indexer_username"}):
                hash: "$(bcrypt ${path "indexer_password"})"
                reserved: true
                backend_roles: ["admin"]
              $(cat ${path "dashboard_username"}):
                hash: "$(bcrypt ${path "dashboard_password"})"
                reserved: true
              EOF
              chown 1000:1000 ${stateDir}/internal_users.yml
            '';
        };
      }
      // lib.genAttrs (map (name: "podman-${name}") (builtins.attrNames containers)) (_: {
        requires = [ "wazuh-setup.service" ];
        after = [ "wazuh-setup.service" ];
      });

      networking.firewall.allowedTCPPorts = [
        1514
        1515
      ];

      services.nginx.virtualHosts."wazuh.${config.homelab.domain}".locations."/" = {
        proxyPass = "http://127.0.0.1:${toString dashboardPort}";
        proxyWebsockets = true;
      };
    };
}
