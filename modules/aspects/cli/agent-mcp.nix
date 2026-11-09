_: {
  flake.modules.homeManager.agent-mcp =
    { lib, pkgs, ... }:
    {
      key = "agent-mcp";

      options.agents.mcpServers = lib.mkOption {
        default = { };
        description = "Local stdio MCP servers every agent harness on this user registers.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              command = lib.mkOption { type = lib.types.str; };
              args = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
              env = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
              };
            };
          }
        );
      };

      config.lib.agents.mergeJson = pkgs.writeShellApplication {
        name = "agent-merge-json";
        runtimeInputs = [
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          target=$1
          current='{}'
          if [[ -s $target ]]; then current=$(cat "$target"); fi
          merged=$(jq -s '.[0] * .[1]' <(printf '%s' "$current") "$2")
          if [[ -L $target || $merged != "$(jq . <<<"$current")" ]]; then
            rm -f "$target"
            mkdir -p "$(dirname "$target")"
            install -m 600 /dev/stdin "$target" <<<"$merged"
          fi
        '';
      };
    };
}
