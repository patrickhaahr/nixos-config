{ inputs, ... }: {
  flake.modules.homeManager.agent-hermes-desktop =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
      ];
    };
}
