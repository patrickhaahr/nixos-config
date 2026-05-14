{ inputs }:
let
  repo = inputs.anthropic-skills;
in {
  frontend-design = repo + "/skills/frontend-design";
}
