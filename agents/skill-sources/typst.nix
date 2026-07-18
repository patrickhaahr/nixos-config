{ inputs }:
let
  repo = inputs.claude-skill-typst;
in
{
  typst = repo + "/skills/typst";
}
