_: {
  flake.modules.homeManager.ffmpeg = { pkgs, ... }: {

    home.packages = [ pkgs.ffmpeg ];
  };
}
