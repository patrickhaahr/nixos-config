{ inputs, pkgs }:
{
  hunk-review = "${
    inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default
  }/skills/hunk-review";
}
