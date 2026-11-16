let
  port = 5000;
  url = "http://zaza.taila757c4.ts.net:${toString port}";
  publicKey = "zaza-cache-1:++x3xekex6IMky+2z5oUYwxEt5F3LGSpYpw7Yspze44=";
in
{
  # zaza serves its /nix/store, signed, to the tailnet; other hosts substitute
  # from it after cache.nixos.org. zaza hosts it because it is always on.
  flake.modules.nixos.binary-cache-server =
    { config, ... }:
    {
      sops.secrets.harmonia_sign_key = { };

      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.sops.secrets.harmonia_sign_key.path ];
        settings.bind = "[::]:${toString port}";
      };

      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ port ];
    };

  flake.modules.nixos.binary-cache = {
    nix.settings = {
      extra-substituters = [ url ];
      extra-trusted-public-keys = [ publicKey ];
      # Off the tailnet the cache is unreachable; give up fast and fall back.
      connect-timeout = 5;
    };
  };
}
