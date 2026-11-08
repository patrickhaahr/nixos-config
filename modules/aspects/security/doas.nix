_: {
  flake.modules.nixos.doas =
    { config, pkgs, ... }:
    let
      sudoShim = pkgs.writeShellApplication {
        name = "sudo";
        text = ''
          run0=${config.systemd.package}/bin/run0
          doas=/run/wrappers/bin/doas

          user=
          while (( $# )); do
            case $1 in
              -u) user=$2; shift 2 ;;
              -u*) user=''${1#-u}; shift ;;
              --) shift; break ;;
              -*) shift ;;
              *) break ;;
            esac
          done
          (( $# )) || { echo "usage: sudo [-u user] command [args...]" >&2; exit 1; }

          if "$run0" --no-ask-password ''${user:+--user="$user"} true 2>/dev/null; then
            exec "$run0" --no-ask-password ''${user:+--user="$user"} -- "$@"
          fi
          if [[ -t 0 ]]; then
            exec "$doas" ''${user:+-u "$user"} "$@"
          fi
          printf 'sudo: root needs the user'"'"'s password on this host and this shell has no terminal.\nStop and ask the user to run:\n  doas%s%s\n' "''${user:+ -u $user}" "$(printf ' %q' "$@")" >&2
          exit 1
        '';
      };
    in
    {
      security = {
        sudo.enable = false;
        doas.enable = true;
        polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (subject.isInGroup("wheel") &&
                (action.id == "org.freedesktop.login1.power-off" ||
                 action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
                 action.id == "org.freedesktop.login1.reboot" ||
                 action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
                 action.id == "org.freedesktop.login1.halt" ||
                 action.id == "org.freedesktop.login1.halt-multiple-sessions")) {
              return polkit.Result.YES;
            }
          });
        '';
      };
      environment.systemPackages = [ sudoShim ];
      system.tools.nixos-rebuild.enableRun0Elevation = true;
    };
}
