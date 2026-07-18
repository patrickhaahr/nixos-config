{ inputs }:
let
  repo = inputs.rhys-sullivan-skills;
  skill = name: repo + "/skills/${name}";
in
{
  how-to-earn-a-billion-dollars = skill "how-to-earn-a-billion-dollars";
  no-ui-flash = skill "no-ui-flash";
  write-better-error-messages = skill "write-better-error-messages";
}
