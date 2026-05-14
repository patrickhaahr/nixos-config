{ inputs }:
let
  repo = inputs.mattpocock-skills;
  engineering = name: repo + "/skills/engineering/${name}";
  productivity = name: repo + "/skills/productivity/${name}";
in {
  diagnose = engineering "diagnose";
  grill-with-docs = engineering "grill-with-docs";
  improve-codebase-architecture = engineering "improve-codebase-architecture";
  tdd = engineering "tdd";
  to-issues = engineering "to-issues";
  to-prd = engineering "to-prd";

  caveman = productivity "caveman";
  grill-me = productivity "grill-me";
  handoff = productivity "handoff";
  write-a-skill = productivity "write-a-skill";
}
