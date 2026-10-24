{ inputs, ... }:
{
  # Shared base for the desktop app and the headless service. The t3code source
  # comes from llm-agents.nix, which tracks upstream daily, so no nightly hashes
  # to pin. Local patches:
  # - Native server modules are built for Node, not Electron's ABI, and the
  #   desktop app spawns its server with its own executable path.
  # - T3's login-shell PATH probe uses POSIX syntax, which Nu cannot parse.
  # - Upstream 0.1.2 renamed the Electron product to "T3 Code (Beta)". Electron
  #   derives its safeStorage keyring key from the product name, so the rename
  #   strands connection-catalog.json (auth/pairing + provider connections),
  #   which is encrypted under the old "T3 Code (Alpha)" key. Keep the old name
  #   so existing state decrypts; revisit if upstream ships a proper migration.
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
                    substituteInPlace "$desktop/libexec/t3code/apps/desktop/package.json" \
                      --replace-fail '"productName": "T3 Code (Beta)"' \
                                     '"productName": "T3 Code (Alpha)"'
                    # Keep the launcher entry in sync with the runtime product
                    # name (see comment above; purely cosmetic). Must run here:
                    # the wrapper's desktop output symlinks into this store
                    # path, so it cannot be patched there.
                    substituteInPlace "$desktop/share/applications/t3code.desktop" \
                      --replace-fail 'Name=T3 Code (Beta)' 'Name=T3 Code (Alpha)'
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
