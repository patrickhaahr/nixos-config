{ inputs }:
let
  repo = inputs.vercel-agent-browser;
in {
  agent-browser = repo + "/skills/agent-browser";
}
