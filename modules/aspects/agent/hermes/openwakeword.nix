{ inputs, ... }: {
  flake.modules.homeManager.agent-hermes-wake-word =
    { pkgs, ... }:
    let
      # Must be the interpreter hermes-agent itself is built against, or
      # hermes-agent.nix's hasPythonModule check drops the package from
      # the wrapper's PYTHONPATH.
      hermesPkgs = inputs.hermes-agent.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};

      # Upstream's pyproject "wake" group cannot resolve on python312
      # (tflite-runtime only ships cp311 wheels) and HM-managed installs
      # refuse runtime lazy-installs, so the wheel is built here.
      openwakeword = hermesPkgs.python312Packages.buildPythonPackage rec {
        pname = "openwakeword";
        version = "0.6.0";
        format = "wheel";
        # numpy/onnxruntime/sounddevice/requests/tqdm already live in the
        # sealed venv at the pinned versions.
        dontCheckRuntimeDeps = true;
        src = hermesPkgs.fetchurl {
          # URL + hash from hermes-agent's locked uv.lock.
          url = "https://files.pythonhosted.org/packages/8a/33/dafd6822bebe463a9098951d06a0d88fb4f8c946ce087025bc4fa132e533/openwakeword-0.6.0-py3-none-any.whl";
          hash = "sha256-b0I6Tjrp3Q480StQ/4q/aWefaHtKs0nXyCwCHA4qvJ0=";
        };
        # The wheel ships no models; openwakeword normally downloads them
        # into site-packages at runtime, which is read-only in the store.
        # custom_verifier_model is removed: __init__ imports it, and its
        # sklearn/torch chain is absent from the venv and unused by Hermes.
        postInstall =
          let
            sitePackages = hermesPkgs.python312.sitePackages;
            models = hermesPkgs.linkFarm "openwakeword-models" {
              "melspectrogram.onnx" = hermesPkgs.fetchurl {
                url = "https://github.com/dscripka/openWakeWord/releases/download/v0.5.1/melspectrogram.onnx";
                hash = "sha256-uisOD4t7h1NposicsTNg/1O6xDbyiVzO2fR5+mXrF28=";
              };
              "embedding_model.onnx" = hermesPkgs.fetchurl {
                url = "https://github.com/dscripka/openWakeWord/releases/download/v0.5.1/embedding_model.onnx";
                hash = "sha256-cNFkKQwdCV0dTuFJvF4AVDJQpzFrWfMdBWz/e9MHXB8=";
              };
              "silero_vad.onnx" = hermesPkgs.fetchurl {
                url = "https://github.com/dscripka/openWakeWord/releases/download/v0.5.1/silero_vad.onnx";
                hash = "sha256-o16/Uv085fFGmyo2FY26dhvEe5c+ozgrMYbKFbH1ryg=";
              };
              # Upstream's "hey hermes" model; the wheel does not package
              # tools/wakewords/, so the engine's bundled-model path does
              # not exist in sealed venvs.
              "hey_hermes.onnx" = hermesPkgs.fetchurl {
                url = "https://raw.githubusercontent.com/NousResearch/hermes-agent/f97608f178d1ffeca59860195ab7da295f7c8e5f/tools/wakewords/hey_hermes.onnx";
                hash = "sha256-sPp7n8WdhVm4OzxNAL8i1YtQP5ZTqX7nHSdSjGYglt8=";
              };
            };
          in
          ''
            modelsDir=$out/${sitePackages}/openwakeword/resources/models
            mkdir -p "$modelsDir"
            cp ${models}/* "$modelsDir"
            sed -i '/custom_verifier_model/d' \
              $out/${sitePackages}/openwakeword/__init__.py
            rm $out/${sitePackages}/openwakeword/custom_verifier_model.py
          '';
      };
      hermesGateway = hermesPkgs.runCommand "hermes-gateway-owner-notice" { } ''
        mkdir -p $out/${hermesPkgs.python312.sitePackages}/gateway
        cp ${inputs.hermes-agent}/gateway/__init__.py $out/${hermesPkgs.python312.sitePackages}/gateway/
        cp ${inputs.hermes-agent}/gateway/config.py $out/${hermesPkgs.python312.sitePackages}/gateway/
        cp ${inputs.hermes-agent}/gateway/config_loader.py $out/${hermesPkgs.python312.sitePackages}/gateway/
        cp ${inputs.hermes-agent}/gateway/run_inbound.py $out/${hermesPkgs.python312.sitePackages}/gateway/
        patch -d $out -p1 < ${../../../../patches/hermes-agent-disable-unauthorized-owner-notices.patch}
      '';
    in
    {
      # Override the package, not services.extraPythonPackages: the module's
      # effectivePackage override would clobber the package's built-in
      # dependency groups (messaging, voice, ...) with the option defaults.
      services.hermes-agent = {
        package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          extraPythonPackages = [
            openwakeword
            hermesGateway
          ];
        };
        settings.wake_word.openwakeword.model = "${openwakeword}/${hermesPkgs.python312.sitePackages}/openwakeword/resources/models/hey_hermes.onnx";
      };
    };
}
