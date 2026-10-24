{ self, ... }:
{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      imports = [ self.modules.nixos.t3code-package ];

      # llm-agents' t3code splits into `out` (t3 CLI) and `desktop` (Electron app
      # + .desktop entry); with meta.outputsToInstall = ["out"], only the CLI
      # reaches systemPackages unless the desktop output is added explicitly.
      environment.systemPackages = [
        pkgs.t3code
        pkgs.t3code.desktop
      ];
      # Opt out of PostHog telemetry; the desktop app inherits this for its server.
      environment.sessionVariables.T3CODE_TELEMETRY_ENABLED = "false";
    };
}
