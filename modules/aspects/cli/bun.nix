{ inputs, ... }:
{
  flake.modules.homeManager.bun =
    { pkgs, ... }:
    let
      # Unpatched upstream bun from llm-agents.nix, which tracks upstream
      # releases instead of the nixpkgs cycle. nixpkgs' patchelf'd bun
      # miscompares its own runtime image (>= 1.3.14) and emits segfaulting
      # `bun build --compile` output; this binary does not.
      bunBin = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.bun-bin;
    in
    {
      # bun-bin ships the binary under share/bun-bin/ with no bin/ output,
      # since it is meant as a `bun build --compile` runtime; expose it as
      # the bun CLI via a symlink.
      home.packages = [
        (pkgs.runCommand "bun" { } ''
          mkdir -p $out/bin
          ln -s ${bunBin}/share/bun-bin/bun-* $out/bin/bun
        '')
      ];
    };
}
