{ self, ... }:
{
  flake.modules.homeManager.specialists =
    { config, lib, ... }:
    let
      cfg = config.agents.specialists;
      instancePrefix = {
        pi = "pi";
        antigravity = "agy";
        claude = "claude";
      };
      instances =
        name: specialist:
        lib.concatMapStringsSep ", " (
          harness: "`${instancePrefix.${harness}}-${name}`"
        ) specialist.harnesses;
    in
    {
      key = "specialists";

      imports = with self.modules.homeManager; [
        agent-skills
        antigravity-specialists
        claude-specialists
        pi-specialists
      ];

      options.agents.specialists = lib.mkOption {
        default = { };
        description = "Specialist agents, each a T3 Code provider instance per harness that sees only its skill bundle, MCP servers and role prompt from `agents/specialists/<name>.md`.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              displayName = lib.mkOption { type = lib.types.str; };
              domain = lib.mkOption {
                type = lib.types.str;
                description = "The work to hand this specialist, listed in every harness's instructions.";
              };
              harnesses = lib.mkOption {
                type = lib.types.nonEmptyListOf (lib.types.enum (lib.attrNames instancePrefix));
                default = [ "pi" ];
                description = "Harnesses that run this specialist; the first is the default an orchestrator delegates to.";
              };
              tools = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                  "read"
                  "write"
                  "edit"
                  "bash"
                ];
                description = "Tools the Pi harness gives this specialist.";
              };
              mcpServers = lib.mkOption {
                type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
                default = { };
                description = "MCP server entries, with `url` for a remote server or `command`, `args` and `env` for a local one.";
              };
              packages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = "Executables the specialist's skills call, added to its PATH.";
              };
            };
          }
        );
      };

      config.agents.extraInstructions = lib.mkIf (cfg != { }) ''
        ## Specialists

        Unless you are a subagent or a delegated child, delegate every task in a specialist's domain, test runs included, with `delegate_task` to one of the domain's `providerInstanceId`s: the first listed, unless the user names another or its models. A specialist is its own agent, not a Claude or Codex child: `pi-<name>` runs Claude models (`claude-code/<model>`) or Codex models (`openai-codex/<model>`), `claude-<name>` runs Claude models in Claude Code and `agy-<name>` runs Gemini models, each with skills and MCP servers that a Claude or Codex child lacks, so only its own instance does its work. It sees only your brief: the goal, input paths, output directory, deliverables and acceptance bar. Name the outcome and leave the design, method and skills to it. Check its deliverables against the brief before you report.

        ${lib.concatStrings (
          lib.mapAttrsToList (name: specialist: ''
            - ${instances name specialist}: ${specialist.domain}
          '') cfg
        )}'';
    };

  flake.modules.homeManager.agent-specialists =
    { pkgs, ... }:
    {
      imports = [ self.modules.homeManager.specialists ];

      agents.specialists = {
        media = {
          displayName = "Media";
          domain = "Generated images, video, audio, speech, music and 3D through fal.";
          mcpServers.fal.url = "https://mcp.fal.ai/mcp-relay";
        };
        cloudflare = {
          displayName = "Cloudflare";
          domain = "Cloudflare Workers, Pages, R2, D1, KV and account changes.";
          mcpServers.cloudflare-api.url = "https://mcp.cloudflare.com/mcp";
          packages = [ pkgs.wrangler ];
        };
        ui = {
          displayName = "UI";
          harnesses = [ "claude" ];
          domain = "Interface design decisions: layout, restyling, motion, design reviews. Code-level UI work with no design decision stays with you.";
          mcpServers.inspo.url = "https://inspomcp.dev/api/mcp";
        };
        qa = {
          displayName = "QA";
          domain = "Driving web and mobile apps live and writing end-to-end tests.";
          mcpServers.e2e = {
            command = "${pkgs.nodejs_22}/bin/npx";
            args = [
              "-y"
              "e2e@0.24.0"
              "mcp"
            ];
          };
          packages = [ pkgs.nodejs_22 ];
        };
      };
    };
}
