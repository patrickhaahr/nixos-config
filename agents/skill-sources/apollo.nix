{ inputs }:
let
  repo = inputs.apollo-skills;
  skill = name: repo + "/skills/${name}";
in
{
  rust-best-practices = skill "rust-best-practices";
}
