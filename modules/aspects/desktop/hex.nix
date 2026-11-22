{ self, inputs, ... }:
{
  flake.modules.nixos.hex =
    { config, lib, ... }:
    let
      hex = lib.getExe config.programs.hex.package;
    in
    {
      imports = [
        inputs.hex.nixosModules.default
        self.modules.nixos.desktop-session
      ];
      programs.hex.enable = true;
      home-manager.sharedModules = [ self.modules.homeManager.hex ];

      desktop.binds = {
        "F9" = {
          command = [
            hex
            "annotate"
            "toggle"
          ];
          repeat = false;
          title = "Toggle Hex Annotate";
        };
        "Ctrl+Alt" = {
          command = [
            hex
            "dictation"
            "toggle"
          ];
          repeat = false;
          title = "Toggle Hex dictation (Ctrl+Alt)";
        };
      };
    };

  flake.modules.homeManager.hex =
    { osConfig, ... }:
    {
      imports = [ inputs.hex.homeManagerModules.default ];

      programs.hex = {
        inherit (osConfig.programs.hex) enable;
        autostart = true;
        package = osConfig.programs.hex.package;
        settings = {
          "labs.filler_words" = true;
          "dictation_processing.default_mode" = {
            name = "Global";
            replacements = [
              {
                matched_phrase = "Next OS";
                output = "NixOS";
              }
              {
                matched_phrase = "next";
                output = "nix";
              }
              {
                matched_phrase = "chest switch";
                output = "just switch";
              }
            ];
          };
          "dictation_processing.modes" = [
            {
              name = "Messaging";
              applications = [ "Signal" ];
              transformations = [ "lowercase" ];
            }
          ];
        };
      };
    };
}
