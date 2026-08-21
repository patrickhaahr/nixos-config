{ inputs }:
let
  repo = inputs.cloudflare-skills;
  skill = name: repo + "/skills/${name}";
in
{
  cloudflare = skill "cloudflare";
  wrangler = skill "wrangler";
}
