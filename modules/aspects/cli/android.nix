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
      environment.systemPackages = [
        sdk
        pkgs.maestro
      ];
      environment.variables = {
        ANDROID_HOME = sdkRoot;
        ANDROID_SDK_ROOT = sdkRoot;
      };

      # Echo unlock/flash over USB without root (rules from Gamer92000/echo-dot-assist).
      # A packaged rules file, not extraRules: uaccess only applies before 73-seat-late.rules,
      # and extraRules lands in 99-local.rules.
      services.udev.packages = [
        (pkgs.writeTextDir "lib/udev/rules.d/51-echo-unlock.rules" ''
          SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", MODE="0660", TAG+="uaccess"
          SUBSYSTEM=="usb", ATTR{idVendor}=="1949", MODE="0660", TAG+="uaccess"
          SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", ATTR{idProduct}=="0c01", MODE="0660", TAG+="uaccess"
          ATTRS{idVendor}=="0e8d", ENV{ID_MM_DEVICE_IGNORE}="1"
        '')
      ];

      # Also let already-running tools discover the SDK at its conventional path.
      home-manager.sharedModules = [
        { home.file."Android/Sdk".source = sdkRoot; }
      ];
    };
}
