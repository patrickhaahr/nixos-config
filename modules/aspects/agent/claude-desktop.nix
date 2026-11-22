{ inputs, ... }:
{
  flake.modules.nixos.claude-desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop
      ];
    };
}
