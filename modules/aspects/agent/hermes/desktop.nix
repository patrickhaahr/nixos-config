# Hermes Desktop as a lite client: the GUI runs on the desktop host and
# connects to the hermes backend on zaza over tailscale (Settings → Gateways).
{ inputs, ... }: {
  flake.modules.homeManager.agent-hermes-desktop =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
      ];
    };
}
