{ inputs }:
let
  repo = inputs.mattpocock-skills;
  engineering = name: repo + "/skills/engineering/${name}";
  #inProgress = name: repo + "/skills/in-progress/${name}";
  productivity = name: repo + "/skills/productivity/${name}";
in {
  codebase-design = engineering "codebase-design";
  diagnosing-bugs = engineering "diagnosing-bugs";
  domain-modeling = engineering "domain-modeling";
  grill-with-docs = engineering "grill-with-docs";
  improve-codebase-architecture = engineering "improve-codebase-architecture";
  prototype = engineering "prototype";
  setup-matt-pocock-skills = engineering "setup-matt-pocock-skills";
  tdd = engineering "tdd";
  to-issues = engineering "to-issues";
  to-prd = engineering "to-prd";

  grilling = productivity "grilling";
  handoff = productivity "handoff";
  teach = productivity "teach";
}
