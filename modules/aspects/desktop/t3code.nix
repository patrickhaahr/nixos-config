{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    let
      t3code =
        (pkgs.t3code.override {
          t3code-unwrapped = pkgs.t3code.unwrapped.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              # Native server modules are built for Node, not Electron's ABI.
              substituteInPlace "$out/libexec/t3code/apps/desktop/dist-electron/main.cjs" \
                --replace-fail 'executablePath: process.execPath,' \
                               'executablePath: "${pkgs.nodejs}/bin/node",'
            '';
          });
        }).overrideAttrs
          (old: {
            buildCommand = old.buildCommand + ''
              # T3's login-shell PATH probe uses POSIX syntax, which Nu cannot parse.
              for program in "$out/bin"/*; do
                wrapProgram "$program" --set SHELL "${pkgs.bashInteractive}/bin/bash"
              done
            '';
          });
    in
    {
      environment.systemPackages = [ t3code ];
      # Opt out of PostHog telemetry; the desktop app inherits this for its server.
      environment.sessionVariables.T3CODE_TELEMETRY_ENABLED = "false";
    };
}
