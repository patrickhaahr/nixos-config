{ inputs }:
let
  repo = inputs.vercel-agent-skills;
  skill = name: repo + "/skills/${name}";
in
{
  react-best-practices = skill "react-best-practices";
}
