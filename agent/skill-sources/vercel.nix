{ inputs }:
let
  repo = inputs.vercel-agent-skills;
  skill = name: repo + "/skills/${name}";
in {
  react-best-practices = skill "react-best-practices";
  react-native-skills = skill "react-native-skills";
  react-view-transitions = skill "react-view-transitions";
  web-design-guidelines = skill "web-design-guidelines";
}
