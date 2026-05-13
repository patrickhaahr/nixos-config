{ ... }: {
  flake.modules.nixos.signal = { pkgs, ... }:
    let
      signalDesktop = pkgs.signal-desktop.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace app/main.main.ts \
            --replace-fail \
              ": ('default' as const);" \
              ": OS.isLinux() ? ('hidden' as const) : ('default' as const);"
        '';
      });
    in {
      environment.systemPackages = [ signalDesktop ];
    };
}
