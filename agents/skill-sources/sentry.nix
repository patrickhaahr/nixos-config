{ inputs }:
let
  repo = inputs.sentry-skills;
  skill = name: repo + "/skills/${name}";
in {
  code-simplifier = skill "code-simplifier";
}
