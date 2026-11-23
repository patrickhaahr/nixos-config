{ self, ... }:
{
  flake.modules.nixos.t3code =
    { lib, pkgs, ... }:
    {
      imports = [
        self.modules.nixos.t3code-package
        self.modules.nixos.desktop-session
      ];

      desktop = {
        startup = [ { command = [ (lib.getExe' pkgs.t3code.desktop "t3code-desktop") ]; } ];
        binds."Ctrl+Shift+2" = {
          command = "gdbus call --session --dest com.t3tools.T3Code.SnapShot --object-path /com/t3tools/SnapShot --method com.t3tools.SnapShot.Capture";
          repeat = false;
        };
      };

      environment.systemPackages = [
        pkgs.t3code
        pkgs.t3code.desktop
      ];

      environment.sessionVariables.T3CODE_TELEMETRY_ENABLED = "false";
    };

}
