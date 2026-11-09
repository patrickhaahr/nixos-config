{ self, inputs, ... }:
let
  agentsSourceDir = ../../../agents;
in
{
  flake.modules.homeManager.codex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      managedSettings = pkgs.writeText "codex-managed-settings.json" (
        builtins.toJSON {
          mcp_servers = lib.mapAttrs (_: server: {
            inherit (server) command args env;
          }) config.agents.mcpServers;
        }
      );
      mergeToml =
        pkgs.writers.writePython3 "codex-merge-settings"
          {
            libraries = [ pkgs.python3Packages.tomlkit ];
          }
          ''
            import json
            import pathlib
            import sys

            import tomlkit

            target = pathlib.Path(sys.argv[1])
            managed = json.loads(pathlib.Path(sys.argv[2]).read_text())
            doc = tomlkit.document()
            if target.exists():
                doc = tomlkit.parse(target.read_text())


            def merge(into, values):
                for key, value in values.items():
                    if isinstance(value, dict) and isinstance(into.get(key), dict):
                        merge(into[key], value)
                    else:
                        into[key] = value


            merge(doc, managed)
            rendered = tomlkit.dumps(doc)
            if not target.exists() or rendered != target.read_text():
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(rendered)
          '';
    in
    {
      imports = [ self.modules.homeManager.agent-mcp ];

      home = {
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex ];
        # Codex only reads ~/.codex/AGENTS.md, never ~/.agents/AGENTS.md
        file.".codex/AGENTS.md".source = agentsSourceDir + "/AGENTS.md";
        activation.codexManagedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${mergeToml} ${config.home.homeDirectory}/.codex/config.toml ${managedSettings}
        '';
      };
    };
}
