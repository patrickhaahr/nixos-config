_: {
  flake.modules.nixos.niri =
    { lib, pkgs, ... }:
    let
      niri = lib.getExe pkgs.niri;
      jq = lib.getExe pkgs.jq;

      mirrorOtherOutput = pkgs.writeShellScriptBin "mirror-other-output" ''
        if ${lib.getExe' pkgs.procps "pkill"} -x wl-mirror; then
          exit 0
        fi

        focused=$(${niri} msg --json focused-output | ${jq} -r '.name')
        target=$(${niri} msg --json outputs | ${jq} -r --arg focused "$focused" \
          '[.[] | select(.logical != null and .name != $focused) | .name][0] // empty')

        if [ -z "$target" ]; then
          exit 1
        fi

        exec ${lib.getExe pkgs.wl-mirror} --fullscreen "$target"
      '';

      action = name: { ${name} = _: { }; };
      throttled = name: _: {
        props.cooldown-ms = 150;
        content = action name;
      };
      workspaceNumbers = map toString (lib.range 1 9);
    in
    {
      wrappers.niri.settings.binds = {
        "Print" = action "screenshot";
        "Ctrl+Print"."screenshot-screen" = _: { props.write-to-disk = false; };
        "Ctrl+Shift+Print" = action "screenshot-screen";
        "Alt+Print"."screenshot-window" = _: { props.write-to-disk = false; };
        "Alt+Shift+Print" = action "screenshot-window";

        "Mod+C" = action "close-window";
        "Super+F" = action "maximize-window-to-edges";
        "Mod+Z" = action "toggle-overview";

        "Mod+H" = action "focus-column-left";
        "Mod+L" = action "focus-column-right";
        "Mod+J" = action "focus-window-down";
        "Mod+K" = action "focus-window-up";
        "Mod+WheelScrollUp" = throttled "focus-column-left";
        "Mod+WheelScrollDown" = throttled "focus-column-right";

        "Mod+Ctrl+H" = action "move-column-left";
        "Mod+Ctrl+L" = action "move-column-right";
        "Mod+Ctrl+J" = action "move-window-down";
        "Mod+Ctrl+K" = action "move-window-up";
        "Mod+Ctrl+WheelScrollUp" = throttled "move-column-left";
        "Mod+Ctrl+WheelScrollDown" = throttled "move-column-right";

        "Mod+Alt+H" = action "consume-or-expel-window-left";
        "Mod+Alt+L" = action "consume-or-expel-window-right";
        "Mod+Alt+WheelScrollUp" = throttled "consume-or-expel-window-left";
        "Mod+Alt+WheelScrollDown" = throttled "consume-or-expel-window-right";

        "Mod+Shift+H" = action "focus-monitor-left";
        "Mod+Shift+L" = action "focus-monitor-right";
        "Mod+P" = action "move-column-to-monitor-left";
        "Mod+Ctrl+Shift+H" = action "move-column-to-monitor-left";
        "Mod+Ctrl+Shift+L" = action "move-column-to-monitor-right";
        "Mod+Ctrl+Shift+Left" = action "move-column-to-monitor-left";
        "Mod+Ctrl+Shift+Right" = action "move-column-to-monitor-right";
        "Mod+Shift+M".spawn = lib.getExe mirrorOtherOutput;
      }
      // lib.genAttrs' workspaceNumbers (
        n: lib.nameValuePair "Super+${n}" { focus-workspace = lib.toInt n; }
      )
      // lib.genAttrs' workspaceNumbers (
        n: lib.nameValuePair "Super+Shift+${n}" { move-column-to-workspace = lib.toInt n; }
      );
    };
}
