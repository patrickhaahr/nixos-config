{ self, ... }:
{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      imports = [ self.modules.nixos.t3code-package ];

      environment.systemPackages = [
        pkgs.t3code
        pkgs.t3code.desktop
      ];

      environment.sessionVariables.T3CODE_TELEMETRY_ENABLED = "false";
    };
}
