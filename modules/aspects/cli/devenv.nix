_: {
  flake.modules.homeManager.devenv =
    { pkgs, lib, ... }:
    {
      home.packages = [ pkgs.devenv ];

      # `use devenv` in .envrc needs the direnvrc that devenv ships.
      xdg.configFile."direnv/direnvrc".text = ''
        source <(${lib.getExe pkgs.devenv} direnvrc)
      '';
    };
}
