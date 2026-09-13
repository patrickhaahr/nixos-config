{ inputs, ... }: {
  flake.modules.homeManager.agent-hermes =
    { pkgs, ... }:
    {
      programs.hermes-agent.enable = true;
    };
}
