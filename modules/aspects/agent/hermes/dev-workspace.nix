# Dev workspace + PR pipeline: gh authenticated only from the
# sops-rendered GITHUB_TOKEN, nixos-config cloned at the root of the
# hermes home (trust boundary — deliberately outside ~/dev). Git/gh
# configuration itself lives in git.nix.
_: {
  flake.modules.nixos.agent-hermes-dev-workspace =
    { lib, pkgs, ... }:
    {
      # Runs in the system manager (so it can order after network-online and
      # the NixOS-level sops render), as hermes with her own ssh config.
      systemd.services.hermes-workspace = {
        description = "Hermes dev workspace bootstrap";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "sops-nix.service"
        ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          User = "hermes";
          Group = "users";
          ExecStart = pkgs.writeShellScript "hermes-workspace" ''
            export HOME=/home/hermes
            # ssh must be on PATH for git's transport lookup.
            export PATH=${pkgs.openssh}/bin:$PATH
            # ~/.config/gh/config.yml is an HM store symlink (read-only); keep
            # gh's mutable state (hosts.yml) where HM doesn't manage.
            export GH_CONFIG_DIR=$HOME/.local/share/gh

            token="$(sed -n 's/^GITHUB_TOKEN=//p' "$HOME/.hermes/.env")"
              if [ -n "$token" ]; then
                printf '%s\n' "$token" | ${lib.getExe pkgs.gh} auth login --with-token || true
              fi

              mkdir -p "$HOME/dev"
              if [ ! -d "$HOME/nixos-config/.git" ]; then
                ${lib.getExe pkgs.git} clone git@github.com:patrickhaahr/nixos-config "$HOME/nixos-config"
              fi
          '';
        };
      };
    };
}
