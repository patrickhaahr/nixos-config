{ inputs, ... }: {
  flake.modules.homeManager.agent-hermes = { config, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    sops = {
      defaultSopsFile = ../../../../secrets/hermes/env.yaml;
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      secrets.hermes_env = {
        # sops owns $HERMES_HOME/.env — all gateway env vars live in the
        # encrypted payload, not on disk in plaintext. config.yaml is
        # declarative (see config.nix), not a secret.
        path = ".hermes/.env";
      };
    };
  };
}
