{ self, inputs, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      inherit
        ((inputs.nixpkgs.lib.nixosSystem {
          modules = [
            self.modules.nixos.niri
            {
              nixpkgs.hostPlatform = system;
              desktop = {
                binds = {
                  "Ctrl+Alt" = {
                    command = [ "chord" ];
                    repeat = false;
                  };
                  "Mod+T".command = "terminal --new";
                };
                startup = [
                  { command = [ "foreground" ]; }
                  {
                    command = [ "background" ];
                    workspace = "2";
                  }
                  {
                    command = "background --shell";
                    workspace = "2";
                  }
                ];
                windowRules = [
                  {
                    appId = "^chat$";
                    atStartup = true;
                    workspace = "2";
                    focus = false;
                  }
                ];
              };
            }
          ];
        }).config.wrappers.niri
        )
        settings
        wrapper
        ;

      failures = lib.runTests {
        testBackgroundStartupRunsOnItsWorkspaceThenReturnsHome = {
          expr = map (
            command: [ (baseNameOf (lib.head command)) ] ++ lib.tail command
          ) settings.spawn-at-startup;
          expected = [
            [
              "niri-focus-workspace"
              "2"
            ]
            [ "background" ]
            [
              "sh"
              "-c"
              "background --shell"
            ]
            [
              "niri-focus-workspace"
              "1"
            ]
            [ "foreground" ]
          ];
        };

        testModifierOnlyChordBindsEveryModifierKeysym = {
          expr = lib.filter (lib.hasPrefix "Ctrl+Alt") (lib.attrNames settings.binds);
          expected = [
            "Ctrl+Alt+Alt_L"
            "Ctrl+Alt+Alt_R"
            "Ctrl+Alt+Control_L"
            "Ctrl+Alt+Control_R"
          ];
        };

        testArgvBindSpawnsWithoutRepeat = {
          expr = settings.binds."Ctrl+Alt+Alt_L" null;
          expected = {
            props.repeat = false;
            content.spawn = [ "chord" ];
          };
        };

        testStringBindSpawnsThroughShell = {
          expr = settings.binds."Mod+T" null;
          expected = {
            props = { };
            content.spawn = [
              "sh"
              "-c"
              "terminal --new"
            ];
          };
        };

        testLayoutBindKeepsNativeAction = {
          expr = lib.attrNames settings.binds."Mod+H";
          expected = [ "focus-column-left" ];
        };

        testWindowRuleMapsEveryField = {
          expr = settings.window-rules;
          expected = [
            {
              matches = [
                {
                  app-id = "^chat$";
                  at-startup = true;
                }
              ];
              open-on-workspace = "2";
              open-focused = false;
            }
          ];
        };
      };
    in
    {
      checks.niri-adapter =
        if failures == [ ] then
          pkgs.runCommand "niri-adapter" { validatedConfig = wrapper; } "touch $out"
        else
          throw "niri adapter tests failed: ${lib.generators.toPretty { } failures}";
    };
}
