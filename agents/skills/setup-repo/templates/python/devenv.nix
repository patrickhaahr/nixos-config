{ pkgs, lib, ... }:

{
  languages.python = {
    enable = true;
    package = pkgs.python315;
    venv.enable = true;
    uv = {
      enable = true;
      sync.enable = true;
    };
    lsp.package = pkgs.basedpyright;
  };

  packages = [
    pkgs.ast-grep
    pkgs.jq
    pkgs.just
    pkgs.ruff
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
