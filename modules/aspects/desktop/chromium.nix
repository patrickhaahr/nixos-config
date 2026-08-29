_: {
  flake.modules.homeManager.chromium =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.chromium ];
    };
}
