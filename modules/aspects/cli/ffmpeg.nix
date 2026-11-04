_: {
  flake.modules.homeManager.ffmpeg = { pkgs, ... }: {
    # Includes libx264, required by T3 Code's Android video stream.
    home.packages = [ pkgs.ffmpeg ];
  };
}
