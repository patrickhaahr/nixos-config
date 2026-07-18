_: {
  flake.modules.homeManager.pi =
    { pkgs, ... }:
    let
      settingsFormat = pkgs.formats.json { };
    in
    {
      home.packages = [ pkgs.pi-coding-agent ];

      home.file.".pi/agent/settings.json".source = settingsFormat.generate "pi-settings.json" {
        npmCommand = [ "${pkgs.nodejs_22}/bin/npm" ];

        packages = [
          "npm:@vigolium/piolium@0.0.12"
          "npm:@hypabolic/pi-hypa@0.1.11"
          "npm:pi-web-access@0.13.0"
          "npm:pi-mcp-adapter@2.11.0"
          "npm:pi-subagents@0.35.1"
        ];
      };
    };
}
