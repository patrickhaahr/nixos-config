{ inputs }:
let
  repo = inputs.mattpocock-skills;
  engineering = name: repo + "/skills/engineering/${name}";
  #inProgress = name: repo + "/skills/in-progress/${name}";
  productivity = name: repo + "/skills/productivity/${name}";
in
{
  code-review = engineering "code-review";
  codebase-design = engineering "codebase-design";
  diagnosing-bugs = engineering "diagnosing-bugs";
  domain-modeling = engineering "domain-modeling";
  grill-with-docs = engineering "grill-with-docs";
  improve-codebase-architecture = engineering "improve-codebase-architecture";
  prototype = engineering "prototype";
  research = engineering "research";
  setup-matt-pocock-skills = engineering "setup-matt-pocock-skills";
  tdd = engineering "tdd";
  to-spec = engineering "to-spec";
  to-tickets = engineering "to-tickets";
  wayfinder = engineering "wayfinder";

  grilling = productivity "grilling";
  handoff = productivity "handoff";
  teach = productivity "teach";
  writing-great-skills = productivity "writing-great-skills";
}
