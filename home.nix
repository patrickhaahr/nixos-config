{ config, pkgs, opencodePkg, self, ... }:

let
  myScripts = import "${self}/pkgs/scripts" { inherit (pkgs) writeShellScriptBin; };
  _ = builtins.trace "myScripts type: ${builtins.typeOf myScripts}" null;
  dotfiles = "${config.home.homeDirectory}/nixos-config/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    nvim = "nvim";
    hypr = "hypr";
    tmux = "tmux";
    ghostty = "ghostty";
    rofi = "rofi";
    waybar = "waybar";
  };
in

{
  home.username = "ph";
  home.homeDirectory = "/home/ph";
  home.stateVersion = "25.11";

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "patrickhaahr";
        email = "git@haahr.me";
      };
      url = {
        "git@github.com:" = {
          insteadOf = ["https://github.com/" "gh:"];
        };
        "git@github.com:patrickhaahr/" = {
          insteadOf = ["ph:"];
        };
      };
      init.defaultBranch = "master";
      core = {
        editor = "nvim";
        excludesfile = "~/.gitignore-global";
      };
      filter = {
        lfs = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
      };
      pull.rebase = true;
      alias = {
        st = "status";
        logd = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
  };
  programs.bash.enable = true; 
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
    ];
  };

  xdg.configFile = builtins.mapAttrs 
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;

  home.packages = with pkgs; [
    neovim
    ripgrep
    nil
    nixpkgs-fmt
    gcc
    tmux
    fish
    rofi
    bat
    fastfetch
    tailscale
    unzip
    hyprshot
    hyprsunset
    hyprlock
    hyprpaper
    waybar
    localsend
    bitwarden-cli
    tree-sitter
    nodejs
    python3
    fd
    wl-clipboard
    bluetui
    lazygit
    fzf
    yazi
  ] ++ builtins.attrValues myScripts;
}
