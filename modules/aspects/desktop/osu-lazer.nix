_: {
  flake.modules.homeManager.osu-lazer = { pkgs, ... }: {
    home.packages = [ pkgs.osu-lazer ];
  };
}
