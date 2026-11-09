{ pkgs, lib, ... }:

{
  packages = [
    pkgs.bun
    pkgs.just
  ];

  git-hooks.hooks = {
    git-file-size-guard = {
      enable = true;
      name = "git-file-size-guard";
      entry = "bash tools/git-file-size-guard";
      pass_filenames = false;
      always_run = true;
    };
    check = {
      enable = true;
      name = "just check";
      entry = "${lib.getExe pkgs.just} check";
      pass_filenames = false;
      always_run = true;
    };
  };
}
