{ inputs, ... }:
{
  flake.modules.homeManager.cliproxyapi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Generate once at activation; keep credentials out of the Nix store.
      readKey = pkgs.writeShellScript "cliproxyapi-read-key" ''
        set -eu
        umask 077
        key_file=${lib.escapeShellArg config.services.cliproxyapi.configDir}/"$1"
        if [ ! -s "$key_file" ]; then
          ${lib.getExe pkgs.openssl} rand -hex 32 > "$key_file"
        fi
        cat "$key_file"
      '';
    in
    {
      imports = [ inputs.cliproxyapi.homeModules.default ];

      services.cliproxyapi = {
        enable = true;
        secretKeyCommand = "${readKey} management-key";
        apiKeyCommand = "${readKey} proxy-key";
        settings = {
          host = "127.0.0.1";
          port = 8317;
          remote-management = {
            allow-remote = false;
            disable-auto-update-panel = true;
          };
        };
      };
    };
}
