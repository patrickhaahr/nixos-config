{ inputs, ... }:
let
  port = 5000;
  url = "http://zaza.taila757c4.ts.net:${toString port}";
  zazaKey = "zaza-cache-1:++x3xekex6IMky+2z5oUYwxEt5F3LGSpYpw7Yspze44=";
  # nika builds; every host accepts paths signed with this key, so `just
  # deploy` can copy nika's closures to any target without trusted users.
  nikaKey = "nika-1:dYsHY+f6OIpGr4pe0N97KVIdP8By7Z5w+5G4Om7DUvM=";
in
{
  # zaza serves its /nix/store, signed, to the tailnet; other hosts substitute
  # from it after cache.nixos.org. zaza hosts it because it is always on;
  # `just deploy` fills it with what nika builds.
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

        nix.settings.extra-trusted-public-keys = [ nikaKey ];

        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ port ];
      };

    binary-cache = {
      nix.settings = {
        extra-substituters = [ url ];
        extra-trusted-public-keys = [
          zazaKey
          nikaKey
        ];
        # Off the tailnet the cache is unreachable; give up fast and fall back.
        connect-timeout = 5;
      };
    };

    # nika signs every path it builds.
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
