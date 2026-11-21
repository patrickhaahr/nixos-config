{ inputs, ... }:
{
  flake.modules.homeManager.bun =
    { pkgs, ... }:
    let

      bunBin = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.bun-bin;
    in
    {

      home.packages = [
        (pkgs.runCommand "bun" { } ''
          mkdir -p $out/bin
          ln -s ${bunBin}/share/bun-bin/bun-* $out/bin/bun
        '')
      ];
    };
}
