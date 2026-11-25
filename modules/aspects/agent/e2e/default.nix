{ self, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    let
      pnpm = pkgs.pnpm_12;
      packages = [
        {
          name = "e2e";
          version = "0.24.0";
        }
        {
          name = "@e2e-dev/web";
          version = "0.16.1";
        }
      ];
      workspaces = [ "@e2e-dev/core" ] ++ map (package: package.name) packages;
    in
    {
      packages.e2e = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "e2e";
        inherit (lib.head packages) version;
        src = pkgs.fetchFromGitHub {
          owner = "e2e-inc";
          repo = "e2e";
          tag = "e2e@${finalAttrs.version}";
          hash = "sha256-0EEogn4SWrJnIR4QcdC1LXB3W8W834Se+pKfhXhSAKY=";
        };
        pnpmWorkspaces = workspaces;
        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (finalAttrs)
            pname
            version
            src
            pnpmWorkspaces
            ;
          inherit pnpm;
          fetcherVersion = 4;
          hash = "sha256-4rf+h2gu2cuntgoxpxhz/WFXPVty+HInXIALSbBT9R0=";
        };
        nativeBuildInputs = [
          pkgs.nodejs_22
          pnpm
          pkgs.pnpmConfigHook
        ];
        buildPhase = ''
          runHook preBuild
          ${lib.concatMapStrings (workspace: "pnpm --filter ${workspace} run build\n") workspaces}
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          deploy() { pnpm --filter "$1" deploy --prod --offline --config.node-linker=hoisted "$2"; }
          deploy e2e $out/lib/node_modules/e2e
          deploy @e2e-dev/web $out/lib/node_modules/e2e/node_modules/@e2e-dev/web
          runHook postInstall
        '';
        passthru = { inherit packages; };
      });
    };

  flake.modules.homeManager.e2e =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      bun = config.programs.bun.package;
      e2e = self.packages.${pkgs.stdenv.hostPlatform.system}.e2e;
      env = config.lib.playwright.env // {
        E2E_PACKAGES = lib.concatMapStringsSep " " (
          package: "${package.name}@${package.version}"
        ) e2e.packages;
      };
    in
    {
      imports = [
        self.modules.homeManager.bun
        self.modules.homeManager.playwright
        self.modules.homeManager.specialists
      ];

      agents.specialists.qa = {
        displayName = "QA";
        domain = "Driving web and mobile apps live and writing end-to-end tests.";
        mcpServers.e2e = {
          command = lib.getExe bun;
          args = [
            "${e2e}/lib/node_modules/e2e/dist/cli/bin.js"
            "mcp"
          ];
          inherit env;
        };
        packages = [
          bun
          pkgs.nodejs_22
        ];
        inherit env;
      };
    };
}
