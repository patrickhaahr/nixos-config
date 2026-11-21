{ self, inputs, ... }:
{
  flake.modules.nixos.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      session = config.desktop;
      homeWorkspace = "1";

      focusWorkspace = pkgs.writeShellScriptBin "niri-focus-workspace" ''
        for _ in $(seq 1 10); do
          if ${lib.getExe pkgs.niri} msg action focus-workspace "$1" >/dev/null 2>&1; then
            exit 0
          fi

          sleep 1
        done
      '';

      modifierKeysyms = {
        Ctrl = "Control";
        Alt = "Alt";
        Shift = "Shift";
        Super = "Super";
      };
      chordKeys =
        key:
        let
          modifiers = lib.splitString "+" key;
        in
        if lib.all (modifier: modifierKeysyms ? ${modifier}) modifiers then
          lib.concatMap (
            modifier:
            map (side: "${key}+${modifierKeysyms.${modifier}}_${side}") [
              "L"
              "R"
            ]
          ) modifiers
        else
          [ key ];

      argv =
        command:
        if builtins.isList command then
          command
        else
          [
            "sh"
            "-c"
            command
          ];

      toBind = bind: _: {
        props = lib.filterAttrs (_: value: value != null) {
          repeat = if bind.repeat then null else false;
          hotkey-overlay-title = bind.title;
        };
        content.spawn = argv bind.command;
      };

      backgroundStartup = lib.filter (entry: entry.workspace != null) session.startup;
      backgroundWorkspaces = lib.unique (map (entry: entry.workspace) backgroundStartup);
      focusOn = workspace: [
        (lib.getExe focusWorkspace)
        workspace
      ];
      startupCommands =
        lib.optionals (backgroundStartup != [ ]) (
          lib.concatMap (
            workspace:
            [ (focusOn workspace) ]
            ++ map (entry: argv entry.command) (
              lib.filter (entry: entry.workspace == workspace) backgroundStartup
            )
          ) backgroundWorkspaces
          ++ [ (focusOn homeWorkspace) ]
        )
        ++ map (entry: argv entry.command) (lib.filter (entry: entry.workspace == null) session.startup);

      toWindowRule =
        rule:
        {
          matches = [ ({ app-id = rule.appId; } // lib.optionalAttrs rule.atStartup { at-startup = true; }) ];
        }
        // lib.optionalAttrs (rule.workspace != null) { open-on-workspace = rule.workspace; }
        // lib.optionalAttrs (rule.focus != null) { open-focused = rule.focus; };

      toOutput =
        output:
        if output.enable then
          lib.optionalAttrs (output.mode != null) { inherit (output) mode; }
          // lib.optionalAttrs (output.position != null) {
            position = _: { props = { inherit (output.position) x y; }; };
          }
        else
          { off = _: { }; };
    in
    {
      imports = [
        inputs.wrapper-modules.nixosModules.niri
        self.modules.nixos.desktop-session
      ];

      wrappers.niri.settings = {
        prefer-no-csd = true;

        workspaces = {
          ${homeWorkspace} = { };
          "2" = { };
        };

        spawn-at-startup = startupCommands;
        window-rules = map toWindowRule session.windowRules;
        outputs = lib.mapAttrs (_: toOutput) session.outputs;
        binds = lib.concatMapAttrs (key: bind: lib.genAttrs (chordKeys key) (_: toBind bind)) session.binds;

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

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
      };

      programs.niri = {
        enable = true;
        package = config.wrappers.niri.wrapper;
      };

      desktop.sessionCommand = lib.getExe' config.programs.niri.package "niri-session";
    };
}
