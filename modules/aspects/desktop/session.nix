_: {
  flake.modules.nixos.desktop-session =
    { config, lib, ... }:
    let
      inherit (lib) mkOption types;
      command = types.either types.str (types.listOf types.str);
      nullable =
        type:
        mkOption {
          type = types.nullOr type;
          default = null;
        };
    in
    {
      key = "desktop-session";

      options.desktop = {
        sessionCommand = nullable types.str // {
          description = "Command greetd starts as the graphical session; set by the window manager adapter.";
        };

        binds = mkOption {
          default = { };
          description = ''
            Keybinds by key chord, such as `Mod+Return`. A chord of modifiers only, such as `Ctrl+Alt`,
            fires when the modifiers alone are pressed. A string command runs through a shell; a list is an argv.
          '';
          type = types.attrsOf (
            types.submodule {
              options = {
                command = mkOption { type = command; };
                repeat = mkOption {
                  type = types.bool;
                  default = true;
                };
                title = nullable types.str;
              };
            }
          );
        };

        startup = mkOption {
          default = [ ];
          description = "Commands started with the session. Entries with a workspace start there without stealing focus.";
          type = types.listOf (
            types.submodule {
              options = {
                command = mkOption { type = command; };
                workspace = nullable types.str;
              };
            }
          );
        };

        windowRules = mkOption {
          default = [ ];
          description = "Where windows open, matched by app id regex.";
          type = types.listOf (
            types.submodule {
              options = {
                appId = mkOption { type = types.str; };
                atStartup = mkOption {
                  type = types.bool;
                  default = false;
                };
                workspace = nullable types.str;
                focus = nullable types.bool;
              };
            }
          );
        };

        outputs = mkOption {
          default = { };
          description = "Monitor settings by connector name, such as `DP-1`.";
          type = types.attrsOf (
            types.submodule {
              options = {
                enable = mkOption {
                  type = types.bool;
                  default = true;
                };
                mode = nullable types.str;
                position = nullable (
                  types.submodule {
                    options = {
                      x = mkOption { type = types.int; };
                      y = mkOption { type = types.int; };
                    };
                  }
                );
              };
            }
          );
        };
      };

      config = lib.mkIf (config.desktop.sessionCommand != null) {
        services.greetd = {
          enable = true;
          settings.default_session.command = config.desktop.sessionCommand;
        };
      };
    };
}
