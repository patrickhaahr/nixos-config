{ inputs }:
let
  skill = name: inputs.marketing-skills + "/skills/${name}";
in
{
  ai-seo = skill "ai-seo";
  seo-audit = skill "seo-audit";
}
