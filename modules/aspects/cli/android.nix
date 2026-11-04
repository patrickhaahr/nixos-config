{
  flake.modules.nixos.android-emulator =
    { pkgs, ... }:
    let
      android = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "35" ];
        includeEmulator = true;
        includeSystemImages = true;
        systemImageTypes = [ "google_apis" ];
        abiVersions = [ "x86_64" ];
        includeCmake = false;
        toolsVersion = null;
      };
      sdk = android.androidsdk.overrideAttrs (previous: {
        # T3 Code discovers avdmanager specifically through cmdline-tools/latest.
        postInstall = (previous.postInstall or "") + ''
          ln -s "$out"/libexec/android-sdk/cmdline-tools/* "$out/libexec/android-sdk/cmdline-tools/latest"
        '';
      });
      sdkRoot = "${sdk}/libexec/android-sdk";
    in
    {
      nixpkgs.config.android_sdk.accept_license = true;
      environment.systemPackages = [ sdk ];
      environment.variables = {
        ANDROID_HOME = sdkRoot;
        ANDROID_SDK_ROOT = sdkRoot;
      };

      # Also let already-running tools discover the SDK at its conventional path.
      home-manager.sharedModules = [
        { home.file."Android/Sdk".source = sdkRoot; }
      ];
    };
}
