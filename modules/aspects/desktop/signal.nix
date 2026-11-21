{ self, ... }:
{
  flake.modules.nixos.signal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      signalDesktop = pkgs.signal-desktop.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace app/main.main.ts \
            --replace-fail \
              ": ('default' as const);" \
              ": OS.isLinux() ? ('hidden' as const) : ('default' as const);"
        '';
      });
    in
    {
      imports = [ self.modules.nixos.desktop-session ];

      options.programs.signal.autostart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Start Signal in the background on workspace 2 at login.";
      };

      config = {
        environment.systemPackages = [ signalDesktop ];

        desktop = lib.mkIf config.programs.signal.autostart {
          startup = [
            {
              command = [ "signal-desktop" ];
              workspace = "2";
            }
          ];
          windowRules = [
            {
              appId = "^signal$";
              atStartup = true;
              workspace = "2";
              focus = false;
            }
          ];
        };
      };
    };
}
