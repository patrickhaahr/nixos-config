{ inputs, ... }: {
  flake.modules.homeManager.lumen = { pkgs, ... }: {
    home.packages = [
      inputs.lumen.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
