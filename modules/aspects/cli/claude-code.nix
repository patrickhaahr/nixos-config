{ inputs, ... }:
let
  agentsSourceDir = ../../../agents;
in
{
  flake.modules.homeManager.claude-code =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      managedSettings = pkgs.writeText "claude-managed-settings.json" (
        builtins.toJSON {
          attribution = {
            commit = "";
            pr = "";
          };
          env.CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-5-5";
        }
      );
      settings = "${config.home.homeDirectory}/.claude/settings.json";
    in
    {
      home = {
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code ];

        file = {
          ".claude/CLAUDE.md".source = agentsSourceDir + "/AGENTS.md";

          ".claude/skills".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
        };

        activation.claudeManagedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$(dirname ${settings})"
          current='{}'
          if [[ -s ${settings} ]]; then current=$(cat ${settings}); fi
          merged=$(${lib.getExe pkgs.jq} -s '.[0] * .[1]' <(printf '%s' "$current") ${managedSettings})
          if [[ $merged != "$(${lib.getExe pkgs.jq} . <<<"$current")" ]]; then
            run install -m 600 /dev/stdin ${settings} <<<"$merged"
          fi
        '';
      };
    };
}
