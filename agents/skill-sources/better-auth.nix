{ inputs }:
let
  repo = inputs.better-auth-skills;
in
{
  better-auth-best-practices = repo + "/better-auth/best-practices";
  create-auth = repo + "/better-auth/create-auth";
  better-auth-security-best-practices = repo + "/security";
}
