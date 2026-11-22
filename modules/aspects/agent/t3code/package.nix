{ inputs, ... }:
{

  flake.modules.nixos.t3code-package = {
    nixpkgs.overlays = [
      (final: prev: {
        t3code =
          let
            llmRepo = inputs.llm-agents;
            formatelf = final.callPackage (llmRepo + "/packages/formatelf/package.nix") { };
            versionCheckHomeHook = final.callPackage (
              llmRepo + "/packages/versionCheckHomeHook/package.nix"
            ) { };
            patched-unwrapped =
              (final.callPackage (llmRepo + "/packages/t3code/unwrapped.nix") {
                inherit formatelf versionCheckHomeHook;
                flake.lib = {
                  maintainers = {
                    dancodes = "dancodes";
                  };
                };
              }).overrideAttrs
                (old: {
                  postInstall = (old.postInstall or "") + ''
                    substituteInPlace "$desktop/libexec/t3code/apps/desktop/dist-electron/main.cjs" \
                      --replace-fail 'executablePath: process.execPath,' \
                                     'executablePath: "${final.nodejs_24}/bin/node",'
                  '';
                });
          in
          (inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.t3code.override {
            t3code-unwrapped = patched-unwrapped;
          }).overrideAttrs
            (old: {
              postFixup = (old.postFixup or "") + ''
                for program in "$out/bin"/* "$desktop/bin"/*; do
                  wrapProgram "$program" --set SHELL "${final.bashInteractive}/bin/bash"
                done
              '';
            });
      })
    ];
  };
}
