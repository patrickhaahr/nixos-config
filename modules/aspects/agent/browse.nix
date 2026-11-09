{ self, ... }:
let
  version = "0.0.16";
in
{
  flake.modules.homeManager.browse =
    { lib, pkgs, ... }:
    let
      unwrapped = pkgs.stdenv.mkDerivation {
        pname = "browse-unwrapped";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@opencode/browse-linux-x64/-/browse-linux-x64-${version}.tgz";
          hash = "sha512-l/adQHsk8y49F/a2Wm6yUYZKrD578zojSLyd/iXQ1pLee0eZFWiW27KI6NbBB7CTWuDKRZEyb+zstZs0Z4pqzg==";
        };
        nativeBuildInputs = [ pkgs.patchelf ];
        dontStrip = true;
        dontPatchELF = true;
        installPhase = ''
          install -Dm755 bin/browse $out/bin/browse
          patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/bin/browse
        '';
        meta = {
          description = "MCP server and relay that let agents drive the user's Chromium browser";
          homepage = "https://github.com/anomalyco/browse";
          license = lib.licenses.mit;
          platforms = [ "x86_64-linux" ];
          mainProgram = "browse";
        };
      };
      env.OPENCODE_BROWSER_AUTO_UPDATE = "off";
      browse = pkgs.writeShellScriptBin "browse" ''
        ${lib.toShellVars env}
        export ${lib.concatStringsSep " " (builtins.attrNames env)}
        exec ${lib.getExe unwrapped} "$@"
      '';
    in
    {
      imports = [ self.modules.homeManager.agent-mcp ];
      home.packages = [ browse ];
      agents.mcpServers.browse = {
        command = lib.getExe browse;
        args = [ "mcp" ];
        inherit env;
      };
    };

  flake.modules.homeManager.browse-headless =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      publishedKey = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjWdgsBDUPCHO2u5bq3/Us1sLm+kiehLZBL0HIu3stwivGW+bgCDsD8KAEMFJcY04u3iudffTeEGdEe8pQfL7BSNRvyslszmvJrsoP7bVUKXrnRTw3CUsRjnwbqMoMElwegiCFUXPnqQ9ZeA2NGEhmWMyDXqqZxOo0z2q66GTgz9McbXOBK2QXYBPjUWxud814wSrE1lIQ2G58nQVeZenI3/PXZ4f1SACn6SdkiCR44NZwz89I1ISxftongLDED/1dlnivqJBzAtN1s2i+jWplLtOmLJJkh1LQ2jP3gWvYY1zT2RHJIw874SSrrhFt4Hguvo/L0Ge7ixvGp5tDAP2wwIDAQAB";
      extension = pkgs.stdenvNoCC.mkDerivation {
        pname = "browse-extension";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://anoma.ly/release/browse/files/0d716106a36a42ab18d4abb2c3d449b88e20bc87e7321128da15feddde1a42c4/browse-extension-${version}.zip";
          hash = "sha256-DXFhBqNqQqsY1Kuyw9RJuI4gvIfnMhEo2hX+3d4aQsQ=";
        };
        nativeBuildInputs = [
          pkgs.unzip
          pkgs.jq
        ];
        unpackPhase = "unzip -q $src -d $out";
        installPhase = ''
          jq --arg key ${publishedKey} '.key = $key' $out/manifest.json > manifest.json
          mv manifest.json $out/manifest.json
        '';
      };
      state = "${config.xdg.stateHome}/browse-headless";
      provision = pkgs.writers.writePython3 "browse-headless-provision" { } ''
        import hashlib
        import json
        import pathlib
        import secrets
        import shutil
        import sys
        import time

        src, ext, profile, state, data = map(pathlib.Path, sys.argv[1:6])
        crockford = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        salt = b"opencode-browser-pairing-v3|code"

        for lock in ("SingletonLock", "SingletonSocket", "SingletonCookie"):
            (profile / lock).unlink(missing_ok=True)

        shutil.rmtree(ext, ignore_errors=True)
        shutil.copytree(src, ext)
        for path in [ext, *ext.rglob("*")]:
            path.chmod(0o700 if path.is_dir() else 0o600)

        tokens = data / "browse" / "browser-tokens.json"
        if tokens.exists() and json.loads(tokens.read_text() or "{}"):
            sys.exit(0)

        code = "".join(crockford[b & 31] for b in secrets.token_bytes(8))
        key = hashlib.pbkdf2_hmac("sha256", code.encode(), salt, 100_000, 32)
        codes = state / "browse" / "pairing-codes.json"
        codes.parent.mkdir(parents=True, exist_ok=True)
        pending = {"codes": []}
        if codes.exists():
            pending = json.loads(codes.read_text())
        expires = int(time.time() * 1000) + 3_600_000
        entry = {"key": key.hex(), "expiresAt": expires}
        pending = {"codes": (pending["codes"] + [entry])[-5:], "failures": 0}
        codes.write_text(json.dumps(pending))
        codes.chmod(0o600)
        bundled = ext / "relay-pairing.json"
        bundled.write_text(json.dumps({"code": code}))
        bundled.chmod(0o600)
      '';
      browse = config.agents.mcpServers.browse.command;
    in
    {
      imports = [ self.modules.homeManager.browse ];

      systemd.user.services = {
        browse-relay = {
          Unit.Description = "browse relay for agents";
          Service = {
            ExecStart = "${browse} serve";
            Restart = "always";
            RestartSec = 5;
          };
          Install.WantedBy = [ "default.target" ];
        };
        browse-chromium = {
          Unit = {
            Description = "Headless Chromium with the browse extension";
            Requires = [ "browse-relay.service" ];
            After = [ "browse-relay.service" ];
          };
          Service = {
            ExecStartPre = "${provision} ${extension} ${state}/extension ${state}/profile ${config.xdg.stateHome} ${config.xdg.dataHome}";
            ExecStart = lib.concatStringsSep " " [
              (lib.getExe pkgs.chromium)
              "--headless=new"
              "--user-data-dir=${state}/profile"
              "--load-extension=${state}/extension"
              "--disable-features=DisableLoadExtensionCommandLineSwitch"
              "--no-first-run"
              "--no-default-browser-check"
              "--password-store=basic"
              "about:blank"
            ];
            Restart = "always";
            RestartSec = 5;
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
