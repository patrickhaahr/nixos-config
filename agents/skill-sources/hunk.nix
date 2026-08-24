{ inputs, pkgs }:
{
  hunk-review = "${inputs.hunk.packages.${pkgs.system}.default}/skills/hunk-review";
}
