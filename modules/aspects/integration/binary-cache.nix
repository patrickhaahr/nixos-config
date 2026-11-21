{ inputs, ... }:
let
  port = 5000;
  url = "http://zaza.taila757c4.ts.net:${toString port}";
  zazaKey = "zaza-cache-1:++x3xekex6IMky+2z5oUYwxEt5F3LGSpYpw7Yspze44=";

  nikaKey = "nika-1:dYsHY+f6OIpGr4pe0N97KVIdP8By7Z5w+5G4Om7DUvM=";

  numtide = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
in
{

  flake.modules.nixos = {
    binary-cache-server =
      { config, ... }:
      {
        sops.secrets.harmonia_sign_key = { };

        services.harmonia.cache = {
          enable = true;
          signKeyPaths = [ config.sops.secrets.harmonia_sign_key.path ];
          settings.bind = "[::]:${toString port}";
        };

        nix.settings = numtide // {
          extra-trusted-public-keys = numtide.extra-trusted-public-keys ++ [ nikaKey ];
        };

        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ port ];
      };

    binary-cache = {
      nix.settings = {
        extra-substituters = [ url ] ++ numtide.extra-substituters;
        extra-trusted-public-keys = [
          zazaKey
          nikaKey
        ]
        ++ numtide.extra-trusted-public-keys;

        connect-timeout = 5;
      };
    };

    binary-cache-builder =
      { config, ... }:
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];

        sops = {
          age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          secrets.nix_signing_key.sopsFile = ../../../secrets/nika.yaml;
        };

        nix.settings.secret-key-files = [ config.sops.secrets.nix_signing_key.path ];
      };
  };
}
