{ inputs, ... }: {
  flake.modules.homeManager.agent-hermes =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
