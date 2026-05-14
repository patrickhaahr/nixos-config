{ ... }: {
  flake.modules.nixos.audio-output = { lib, pkgs, config, ... }:
    let
      cfg = config.services.audio-output;
    in {
      options.services.audio-output = {
        enable = lib.mkEnableOption "shared audio output toggle";
        headphones = lib.mkOption {
          type = lib.types.str;
          description = "PipeWire sink name for the headphone output.";
        };
        speaker = lib.mkOption {
          type = lib.types.str;
          description = "PipeWire sink name for the speaker output.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "toggle-audio-output" ''
            wpctl_status() {
              ${lib.getExe' pkgs.wireplumber "wpctl"} status -n
            }

            current_default="$(wpctl_status | ${lib.getExe pkgs.gnugrep} '^Settings$' -A 5 | ${lib.getExe pkgs.gnugrep} 'Audio/Sink' | ${lib.getExe pkgs.gnused} 's/.*Audio\/Sink[[:space:]]*//')"

            if [ "$current_default" = "${cfg.speaker}" ]; then
              target_name="${cfg.headphones}"
            else
              target_name="${cfg.speaker}"
            fi

            target_id="$(wpctl_status | ${lib.getExe pkgs.gnugrep} "$target_name" | ${lib.getExe pkgs.gnused} 's/^[^0-9]*\([0-9][0-9]*\)\..*/\1/' | ${lib.getExe' pkgs.coreutils "head"} -n 1)"

            if [ -z "$target_id" ]; then
              exit 1
            fi

            ${lib.getExe' pkgs.wireplumber "wpctl"} set-default "$target_id"

            for input_id in $(wpctl_status | ${lib.getExe pkgs.gnugrep} '^[[:space:]]*[0-9][0-9]*\.[[:space:]].*input[[:space:]]*$' | ${lib.getExe pkgs.gnused} 's/^[[:space:]]*\([0-9][0-9]*\)\..*/\1/'); do
              ${lib.getExe' pkgs.wireplumber "wpctl"} move "$input_id" "$target_id"
            done
          '')
        ];
      };
    };
}
