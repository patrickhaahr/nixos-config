{ inputs, ... }: {
  flake.modules.homeManager.typesafe =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        defaultSopsFile = ../../../secrets/nika.yaml;
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        secrets.typesafe_api_key.path = ".config/typesafe/api-key";
      };

      # Load the sops-rendered key into the shell environment at startup;
      # agents (opencode etc.) inherit it from interactive shells.
      programs.nushell.extraConfig = lib.mkBefore ''
        let keyfile = $"($env.HOME)/.config/typesafe/api-key"
        if ($keyfile | path exists) {
          $env.TYPESAFE_API_KEY = (open --raw $keyfile | str trim)
        }
      '';
    };
}
