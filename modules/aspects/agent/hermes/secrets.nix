{ inputs, ... }: {
  flake.modules.homeManager.agent-hermes = { config, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    sops = {
      defaultSopsFile = ../../../../secrets/hermes/env.yaml;
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      secrets.hermes_env = {

        path = ".hermes/.env";
      };
      secrets.openhome_api_key.path = ".config/openhome/api-key";
    };
  };
}
