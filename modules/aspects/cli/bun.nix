{ inputs, ... }:
{
  flake.modules.homeManager.bun =
    { pkgs, ... }:
    let
      bunBin = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.bun-bin;
    in
    {
      key = "bun";

      programs.bun = {
        enable = true;
        package = pkgs.runCommand "bun" { meta.mainProgram = "bun"; } ''
          mkdir -p $out/bin
          ln -s ${bunBin}/share/bun-bin/bun-* $out/bin/bun
        '';
      };
    };
}
