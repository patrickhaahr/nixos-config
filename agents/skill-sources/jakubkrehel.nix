{ inputs }:
let
  skill = name: inputs.jakubkrehel-skills + "/skills/${name}";
in
{
  better-accessibility = skill "better-accessibility";
  better-colors = skill "better-colors";
  better-interface = skill "better-interface";
  better-layout = skill "better-layout";
  better-typography = skill "better-typography";
  better-ui = skill "better-ui";
  better-writing = skill "better-writing";
  interface-review = skill "interface-review";
}
