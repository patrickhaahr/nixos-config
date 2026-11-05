{ inputs, ... }:
{
  flake.modules.nixos.hex = {
    imports = [ inputs.hex.nixosModules.default ];
    programs.hex.enable = true;
  };

  flake.modules.homeManager.hex =
    { osConfig, ... }:
    {
      imports = [ inputs.hex.homeManagerModules.default ];

      programs.hex = {
        enable = true;
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
