{ self, inputs, ... }: {
  flake.modules.nixos.niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.myNiri =
      let
        heliumNoKeyring = pkgs.writeShellScriptBin "helium-no-keyring" ''
          exec ${lib.getExe self'.packages.helium-no-keyring} "$@"
        '';
      in
      inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          spawn-at-startup = [
            (lib.getExe self'.packages.noctalia-shell)
            (lib.getExe pkgs.ghostty)
            (lib.getExe heliumNoKeyring)
          ];

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          outputs = {
            "HDMI-A-1" = {
              position = _: {
                props = { x = 0; y = 0; };
              };
            };
            "DVI-D-1" = {
              off = _: { };
            };
          };

          input.keyboard.xkb = {
            layout = "dk";
            options = "caps:escape";
          };

          layout = {
            gaps = 0;
            focus-ring.off = _: { };
          };

          hotkey-overlay.skip-at-startup = _: { };

          window-rule = [ ];

          binds = {
            "Mod+Return".spawn = "ghostty";
            "Mod+T".spawn = "ghostty";
            "Mod+B".spawn = lib.getExe heliumNoKeyring;
            "Mod+Q".close-window = _: { };
            "Mod+Shift+H".focus-monitor-left = _: { };
            "Mod+Shift+L".focus-monitor-right = _: { };
            "Mod+Ctrl+Shift+H".move-column-to-monitor-left = _: { };
            "Mod+Ctrl+Shift+L".move-column-to-monitor-right = _: { };
            "Mod+Ctrl+Shift+Left".move-column-to-monitor-left = _: { };
            "Mod+Ctrl+Shift+Right".move-column-to-monitor-right = _: { };
            "Mod+Space".spawn-sh = "${lib.getExe self'.packages.noctalia-shell} ipc call launcher toggle";
            "Mod+E".spawn = "nautilus";
            "Super+F"."maximize-window-to-edges" = _: { };
          } // {
            "Super+1"."focus-workspace" = 1;
            "Super+2"."focus-workspace" = 2;
            "Super+3"."focus-workspace" = 3;
            "Super+4"."focus-workspace" = 4;
            "Super+5"."focus-workspace" = 5;
            "Super+6"."focus-workspace" = 6;
            "Super+7"."focus-workspace" = 7;
            "Super+8"."focus-workspace" = 8;
            "Super+9"."focus-workspace" = 9;
            "Super+Shift+1"."move-column-to-workspace" = 1;
            "Super+Shift+2"."move-column-to-workspace" = 2;
            "Super+Shift+3"."move-column-to-workspace" = 3;
            "Super+Shift+4"."move-column-to-workspace" = 4;
            "Super+Shift+5"."move-column-to-workspace" = 5;
            "Super+Shift+6"."move-column-to-workspace" = 6;
            "Super+Shift+7"."move-column-to-workspace" = 7;
            "Super+Shift+8"."move-column-to-workspace" = 8;
            "Super+Shift+9"."move-column-to-workspace" = 9;
          };
        };
      };

    packages.helium-no-keyring = pkgs.writeShellScriptBin "helium-no-keyring" ''
      exec ${lib.getExe inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default} --password-store=basic "$@"
    '';
  };
}
