{ inputs }:
let
  repo = inputs.dotnet-skillz;
in {
  ilspy-decompile = repo + "/skills/ilspy-decompile";
}
