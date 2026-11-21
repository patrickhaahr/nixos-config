_: {
  flake.modules.homeManager.devenv =
    { pkgs, lib, ... }:
    {
      home.packages = [ pkgs.devenv ];

      xdg.configFile."direnv/direnvrc".text = ''
        source <(${lib.getExe pkgs.devenv} direnvrc)
      '';
    };
}
