{ self, ... }:
{
  flake.modules.homeManager.playwright =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      slice = "playwright";
      browsersPath = "${config.xdg.dataHome}/playwright-browsers";

      browser = pkgs.writeShellScript "playwright-chromium" ''
        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect --slice=${slice}.slice \
          ${lib.getExe pkgs.chromium} "$@" --use-angle=vulkan --ignore-gpu-blocklist --enable-gpu
      '';

      install =
        name: executables:
        pkgs.runCommand "playwright-${name}" { } ''
          mkdir $out
          touch $out/INSTALLATION_COMPLETE
          ${lib.concatStrings (
            lib.mapAttrsToList (path: target: ''
              mkdir -p "$(dirname "$out/${path}")"
              ln -s ${target} "$out/${path}"
            '') executables
          )}
        '';

      chromium = install "chromium" {
        "chrome-linux/chrome" = browser;
        "chrome-linux/headless_shell" = browser;
        "chrome-linux64/chrome" = browser;
        "chrome-headless-shell-linux64/chrome-headless-shell" = browser;
      };
      ffmpeg = install "ffmpeg" { ffmpeg-linux = lib.getExe pkgs.ffmpeg-headless; };

      everyRevision = pkgs.runCommand "playwright-browsers" { } ''
        mkdir $out
        for revision in {1000..1999}; do
          ln -s ${chromium} $out/chromium-$revision
          ln -s ${chromium} $out/chromium_headless_shell-$revision
          ln -s ${ffmpeg} $out/ffmpeg-$revision
        done
      '';

      env = {
        PLAYWRIGHT_BROWSERS_PATH = browsersPath;
        PLAYWRIGHT_SKIP_BROWSER_GC = "1";
      };
    in
    {
      key = "playwright";

      imports = [ self.modules.homeManager.chromium ];

      home.sessionVariables = env;
      systemd.user.sessionVariables = env;

      home.activation.playwrightBrowsers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArg browsersPath}
        run cp -dR --no-preserve=mode --remove-destination ${everyRevision}/. ${lib.escapeShellArg browsersPath}/
      '';

      systemd.user.slices.${slice} = {
        Unit.Description = "Browsers driven by Playwright";
        Slice = {
          MemoryMax = "4G";
          MemorySwapMax = 0;
        };
      };

      lib.playwright = { inherit env; };
    };
}
