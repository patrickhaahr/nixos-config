{ self, ... }: {
  flake.modules.nixos.screenshot-ocr = { pkgs, ... }: {
    environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.niriOcrScreenshot ];
  };

  perSystem = { pkgs, lib, ... }: {
    packages.niriOcrScreenshot = pkgs.writeShellApplication {
      name = "niri-ocr-screenshot";
      runtimeInputs = with pkgs; [ coreutils grim slurp tesseract wl-clipboard libnotify ];
      text = ''
        set -eu

        selection="$(${lib.getExe pkgs.slurp})" || exit 0
        image="$(mktemp --suffix=.png)"
        trap 'rm -f "$image"' EXIT

        ${lib.getExe pkgs.grim} -g "$selection" "$image"

        text="$(${lib.getExe pkgs.tesseract} -l eng+dan "$image" stdout 2>/dev/null | tr -d '\f')"

        if [ -z "$text" ]; then
          ${lib.getExe' pkgs.libnotify "notify-send"} "OCR screenshot" "No text detected"
          exit 1
        fi

        printf '%s' "$text" | ${lib.getExe' pkgs.wl-clipboard "wl-copy"} --type text/plain
        ${lib.getExe' pkgs.libnotify "notify-send"} "OCR screenshot" "Copied text to clipboard"
      '';
    };
  };
}
