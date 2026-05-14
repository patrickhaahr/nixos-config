{ inputs, ... }:
let
  version = "0.8.3";
  releases = {
    x86_64-linux = {
      artifact = "Handy_${version}_amd64.AppImage";
      hash = "sha256-8rQJVpABydLXGlyLNIdw/cilAcmwvmAb93VoaJJ+KJQ=";
    };
    aarch64-linux = {
      artifact = "Handy_${version}_aarch64.AppImage";
      hash = "sha256-CgSlTk3mJN/o1NuKeRKt7f+iRHPBqMUAhKhHDVBQNTE=";
    };
  };
in {
  flake.modules.nixos.handy = { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      release = releases.${system} or (throw "Handy is not packaged for ${system}");
      combinedAlsaPlugins = pkgs.symlinkJoin {
        name = "handy-combined-alsa-plugins";
        paths = [
          "${pkgs.pipewire}/lib/alsa-lib"
          "${pkgs.alsa-plugins}/lib/alsa-lib"
        ];
      };
      alsaConfig = pkgs.writeText "handy-alsa.conf" ''
        <${pkgs.alsa-lib}/share/alsa/alsa.conf>
        <${pkgs.pipewire}/share/alsa/alsa.conf.d/50-pipewire.conf>
        <${pkgs.pipewire}/share/alsa/alsa.conf.d/99-pipewire-default.conf>
      '';
      basePackage = pkgs.appimageTools.wrapType2 {
        pname = "handy";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://github.com/cjpais/Handy/releases/download/v${version}/${release.artifact}";
          hash = release.hash;
        };
        extraPkgs = appPkgs:
          with appPkgs; [
            alsa-lib
            alsa-plugins
            glib
            glib-networking
            gtk-layer-shell
            gtk3
            libayatana-appindicator
            libevdev
            libsoup_3
            libx11
            libxtst
            onnxruntime
            pipewire
            vulkan-loader
            webkitgtk_4_1
            gst_all_1.gstreamer
            gst_all_1.gst-plugins-base
            gst_all_1.gst-plugins-good
            gst_all_1.gst-plugins-bad
            gst_all_1.gst-plugins-ugly
          ];
      };
      package = pkgs.symlinkJoin {
        name = "handy-${version}";
        paths = [ basePackage ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/handy" \
            --add-flags "--start-hidden" \
            --set ALSA_CONFIG_PATH "${alsaConfig}" \
            --set ALSA_PLUGIN_DIR "${combinedAlsaPlugins}" \
            --set WEBKIT_DISABLE_DMABUF_RENDERER 1
        '';
      };
    in {
      imports = [ "${inputs.handy}/nix/module.nix" ];

      programs.handy = {
        enable = true;
        inherit package;
      };

      environment.systemPackages = [ pkgs.wtype ];

      home-manager.users.ph.imports = [ "${inputs.handy}/nix/hm-module.nix" ];
      home-manager.users.ph.services.handy = {
        enable = true;
        inherit package;
      };
    };
}
