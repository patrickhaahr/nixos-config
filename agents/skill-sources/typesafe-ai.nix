{ inputs }:
let
  repo = inputs.typesafe-skills;
in
{
  typesafe-ai = repo + "/skills/typesafe-ai";
}
