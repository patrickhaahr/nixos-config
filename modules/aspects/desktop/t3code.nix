{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.t3code ];
      # Opt out of PostHog telemetry; the desktop app inherits this for its server.
      environment.sessionVariables.T3CODE_TELEMETRY_ENABLED = "false";
    };
}
