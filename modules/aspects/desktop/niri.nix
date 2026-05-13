{ self, inputs, ... }: {
  flake.modules.nixos.niri = { pkgs, ... }: {
    hardware.i2c.enable = true;

    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  flake.modules.nixos."niri-dp1-1080p" = { lib, pkgs, ... }: {
    programs.niri.package = lib.mkForce self.packages.${pkgs.stdenv.hostPlatform.system}.myNiriDp11080p;
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages =
      let
        heliumNoKeyring = pkgs.writeShellScriptBin "helium-no-keyring" ''
          exec ${lib.getExe self'.packages.helium-no-keyring} "$@"
        '';
        spotifyAutoplay = pkgs.writeShellScriptBin "spotify-autoplay" ''
          spotify &

          for _ in $(seq 1 60); do
            if ${lib.getExe pkgs.playerctl} -p spotify status >/dev/null 2>&1; then
              exec ${lib.getExe pkgs.playerctl} -p spotify play
            fi

            sleep 1
          done
        '';
        focusWorkspace2 = pkgs.writeShellScriptBin "focus-workspace-2" ''
          for _ in $(seq 1 10); do
            if ${lib.getExe pkgs.niri} msg action focus-workspace 2 >/dev/null 2>&1; then
              exit 0
            fi

            sleep 1
          done
        '';
        focusWorkspace1 = pkgs.writeShellScriptBin "focus-workspace-1" ''
          for _ in $(seq 1 10); do
            if ${lib.getExe pkgs.niri} msg action focus-workspace 1 >/dev/null 2>&1; then
              exit 0
            fi

            sleep 1
          done
        '';
        openhomeIr = command: ''
          OPENHOME_TOKEN="$(<"$HOME/.config/secrets/openhome")"
          ${lib.getExe pkgs.curl} -X POST https://openhome.haahr.me/api/ir/send \
            -H "Authorization: Bearer $OPENHOME_TOKEN" \
            -H "Content-Type: application/json" \
            -d '${builtins.toJSON { inherit command; }}'
        '';
        mkNiri = settings: inputs.wrapper-modules.wrappers.niri.wrap {
          inherit pkgs settings;
        };
        baseSettings = {
          prefer-no-csd = true;

          workspaces = {
            "1" = { };
            "2" = { };
          };

          spawn-at-startup = [
            (lib.getExe focusWorkspace2)
            "signal-desktop"
            (lib.getExe spotifyAutoplay)
            (lib.getExe focusWorkspace1)
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

          input = {
            focus-follows-mouse = _: { };

            keyboard.xkb = {
              layout = "dk";
              variant = "nodeadkeys";
              options = "caps:escape";
            };

            mouse = {
              accel-profile = "flat";
              accel-speed = -0.6;
            };
          };

          layout = {
            gaps = 0;
            focus-ring.off = _: { };
          };

          screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

          hotkey-overlay.skip-at-startup = _: { };

          window-rules = [
            {
              matches = [
                {
                  app-id = "^com\\.mitchellh\\.ghostty$";
                  at-startup = true;
                }
              ];
              open-on-workspace = "1";
            }
            {
              matches = [
                {
                  app-id = "^helium$";
                  at-startup = true;
                }
              ];
              open-on-workspace = "1";
            }
            {
              matches = [
                {
                  app-id = "^signal$";
                  at-startup = true;
                }
              ];
              open-on-workspace = "2";
              open-focused = false;
            }
            {
              matches = [
                {
                  app-id = "^Spotify$";
                  at-startup = true;
                }
              ];
              open-on-workspace = "2";
              open-focused = false;
            }
          ];

          binds = {
            "Mod+Return".spawn = "ghostty";
            "Mod+T".spawn = "ghostty";
            "Mod+B".spawn = lib.getExe heliumNoKeyring;
            "Print".screenshot = _: { };
            "Ctrl+Print"."screenshot-screen" = _: {
              props.write-to-disk = false;
            };
            "Ctrl+Shift+Print"."screenshot-screen" = _: { };
            "Alt+Print"."screenshot-window" = _: {
              props.write-to-disk = false;
            };
            "Alt+Shift+Print"."screenshot-window" = _: { };
            "Mod+C".close-window = _: { };
            "Mod+H".focus-column-left = _: { };
            "Mod+L".focus-column-right = _: { };
            "Mod+Ctrl+H".move-column-left = _: { };
            "Mod+Ctrl+L".move-column-right = _: { };
            "Mod+J".focus-window-down = _: { };
            "Mod+K".focus-window-up = _: { };
            "Mod+Ctrl+J".move-window-down = _: { };
            "Mod+Ctrl+K".move-window-up = _: { };
            "Mod+Alt+H"."consume-or-expel-window-left" = _: { };
            "Mod+Alt+L"."consume-or-expel-window-right" = _: { };
            "Mod+Shift+H".focus-monitor-left = _: { };
            "Mod+Shift+L".focus-monitor-right = _: { };
            "Mod+Ctrl+Shift+H".move-column-to-monitor-left = _: { };
            "Mod+Ctrl+Shift+L".move-column-to-monitor-right = _: { };
            "Mod+Ctrl+Shift+Left".move-column-to-monitor-left = _: { };
            "Mod+Ctrl+Shift+Right".move-column-to-monitor-right = _: { };
            "Mod+Space".spawn-sh = "${lib.getExe self'.packages.noctalia-shell} ipc call launcher toggle";
            "Mod+E".spawn = "nautilus";
            "Super+F"."maximize-window-to-edges" = _: { };
            "Super+M".spawn-sh = openhomeIr "mute";
            "Super+Left".spawn-sh = openhomeIr "bluetooth";
            "Super+Right".spawn-sh = openhomeIr "optical";
            "Super+Up".spawn-sh = openhomeIr "volume-up";
            "Super+Down".spawn-sh = openhomeIr "volume-down";
            "Mod+F9".spawn-sh = "${lib.getExe self'.packages.noctalia-shell} ipc call brightness decrease";
            "Mod+Shift+F9".spawn-sh = "${lib.getExe self'.packages.noctalia-shell} ipc call brightness increase";
            "Mod+Alt+F10".spawn-sh = "${lib.getExe self'.packages.noctalia-shell} ipc call nightLight toggle";
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
      in {
        myNiri = mkNiri baseSettings;
        myNiriDp11080p = mkNiri (baseSettings // {
          outputs = baseSettings.outputs // {
            "DP-1".mode = "1920x1080";
          };
        });
        helium-no-keyring = pkgs.writeShellScriptBin "helium-no-keyring" ''
          exec ${lib.getExe inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default} --password-store=basic "$@"
        '';
      };
  };
}
