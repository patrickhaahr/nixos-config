{ self, inputs, ... }:
let
  port = 5000;
  url = "http://zaza.taila757c4.ts.net:${toString port}";
  zazaKey = "zaza-cache-1:++x3xekex6IMky+2z5oUYwxEt5F3LGSpYpw7Yspze44=";

  nikaKey = "nika-1:dYsHY+f6OIpGr4pe0N97KVIdP8By7Z5w+5G4Om7DUvM=";

  numtide = {
    extra-substituters = [ "https://cache.numtide.com?priority=50" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
in
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      settingsOf = host: self.nixosConfigurations.${host}.config.nix.settings;
      listOf = host: name: (settingsOf host).${name} or [ ] ++ (settingsOf host)."extra-${name}" or [ ];
      hosts = lib.attrNames self.nixosConfigurations;
      clients = lib.remove "zaza" hosts;
      missing = {
        nikaKey = lib.filter (host: !lib.elem nikaKey (listOf host "trusted-public-keys")) hosts;
        zazaKey = lib.filter (host: !lib.elem zazaKey (listOf host "trusted-public-keys")) clients;
        substituter = lib.filter (host: !lib.elem url (listOf host "substituters")) clients;
      };
    in
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        binary-cache-wiring =
          if lib.all (hosts: hosts == [ ]) (lib.attrValues missing) then
            pkgs.runCommand "binary-cache-wiring" { } "touch $out"
          else
            throw "hosts missing binary cache wiring: ${builtins.toJSON missing}";
      };
    };

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
