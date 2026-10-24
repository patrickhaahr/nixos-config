{ inputs, ... }:
{
  flake.modules.nixos.chatgpt =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.chatgpt
      ];
    };
}
