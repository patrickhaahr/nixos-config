{ inputs }:
let
  repo = inputs.better-auth-skills;
in
{
  better-auth-best-practices = repo + "/better-auth/best-practices";
  better-auth-security-best-practices = repo + "/security";
}
