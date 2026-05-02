{ self, ... }: {
  perSystem = { pkgs, ... }: {
    packages.openlinkhub = pkgs.buildGoModule rec {
      pname = "openlinkhub";
      version = "0.8.5";

      src = pkgs.fetchFromGitHub {
        owner = "jurkovic-nikola";
        repo = "OpenLinkHub";
        tag = version;
        hash = "sha256-sdENc4A9X9cTxVUe3QX26OcA4mkv4utJDKWpbEFGYgU=";
      };

      proxyVendor = true;
      vendorHash = "sha256-/itomxsbTDT7ML52bpUfDZIBZ/Rh/zx4Blg+PP7m7gE=";

      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.udev pkgs.pipewire ];
      env.CGO_CFLAGS_ALLOW = "-fno-strict-overflow";

      postInstall = ''
        mkdir -p $out/share/openlinkhub
        cp -r web static database $out/share/openlinkhub/
        cp 99-openlinkhub.rules $out/share/openlinkhub/99-openlinkhub.rules
      '';

      meta.mainProgram = "OpenLinkHub";
    };
  };

  flake.modules.nixos.openlinkhub = { lib, pkgs, ... }:
    let
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.openlinkhub;
      dataDir = "/var/lib/openlinkhub";
      packageShare = "${package}/share/openlinkhub";
      writeableDatabaseDirs = [
        "led"
        "profiles"
        "rgb"
        "macros"
        "key-assignments"
        "temperatures"
      ];
      readOnlyDatabaseDirs = [
        "language"
        "external"
        "keyboard"
        "nexus"
        "motherboard"
      ];
      setupScript = pkgs.writeShellScript "openlinkhub-setup" ''
        set -euo pipefail

        install -d -o openlinkhub -g openlinkhub -m 0755 ${dataDir}
        install -d -o openlinkhub -g openlinkhub -m 0755 ${dataDir}/database
        install -d -o openlinkhub -g openlinkhub -m 0755 ${dataDir}/database/lcd
        install -d -o openlinkhub -g openlinkhub -m 0755 ${dataDir}/database/lcd/images

        ln -sfn ${packageShare}/web ${dataDir}/web
        ln -sfn ${packageShare}/static ${dataDir}/static
        ln -sfn ${packageShare}/database/rgb.json ${dataDir}/database/rgb.json

        ${lib.concatMapStringsSep "\n" (dir: ''
          install -d -o openlinkhub -g openlinkhub -m 0755 ${dataDir}/database/${dir}
        '') writeableDatabaseDirs}

        ${lib.concatMapStringsSep "\n" (dir: ''
          ln -sfn ${packageShare}/database/${dir} ${dataDir}/database/${dir}
        '') readOnlyDatabaseDirs}

        if [ ! -e ${dataDir}/database/scheduler.json ]; then
          install -o openlinkhub -g openlinkhub -m 0644 ${packageShare}/database/scheduler.json ${dataDir}/database/scheduler.json
        fi

        if [ ! -e ${dataDir}/database/lcd/background.jpg ]; then
          install -o openlinkhub -g openlinkhub -m 0644 ${packageShare}/database/lcd/background.jpg ${dataDir}/database/lcd/background.jpg
        fi

        if [ ! -e ${dataDir}/config.json ]; then
          cat > ${dataDir}/config.json <<'EOF'
{
  "debug": false,
  "listenPort": 27003,
  "listenAddress": "127.0.0.1",
  "cpuSensorChip": "",
  "manual": false,
  "frontend": true,
  "metrics": false,
  "memory": false,
  "memorySmBus": "i2c-0",
  "memoryType": 5,
  "exclude": [],
  "memorySku": "",
  "resumeDelay": 15000,
  "logFile": "",
  "logLevel": "info",
  "enhancementKits": [],
  "temperatureOffset": 0,
  "amdGpuIndex": 0,
  "amdsmiPath": "",
  "checkDevicePermission": false,
  "cpuTempFile": "",
  "graphProfiles": true,
  "ramTempViaHwmon": true,
  "nvidiaGpuIndex": [0],
  "defaultNvidiaGPU": 0,
  "openRGBPort": 6743,
  "enableOpenRGBTargetServer": false,
  "enableGamepad": true,
  "enableMotherboard": false,
  "motherboardBiosOnExit": false,
  "memoryRegisterOverride": []
}
EOF
          chown openlinkhub:openlinkhub ${dataDir}/config.json
          chmod 0644 ${dataDir}/config.json
        fi

        if [ ! -e ${dataDir}/database/lcd/images/background.jpg ]; then
          install -o openlinkhub -g openlinkhub -m 0644 ${packageShare}/database/lcd/background.jpg ${dataDir}/database/lcd/images/background.jpg
        fi
      '';
    in {
      users.users.openlinkhub = {
        isSystemUser = true;
        group = "openlinkhub";
        home = dataDir;
      };

      users.groups.openlinkhub = { };

      environment.systemPackages = [ package ];

      services.udev.packages = [
        (pkgs.writeTextDir "lib/udev/rules.d/99-openlinkhub.rules" (builtins.readFile "${packageShare}/99-openlinkhub.rules"))
      ];

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0755 openlinkhub openlinkhub -"
        "d ${dataDir}/database 0755 openlinkhub openlinkhub -"
        "d ${dataDir}/database/lcd 0755 openlinkhub openlinkhub -"
        "d ${dataDir}/database/lcd/images 0755 openlinkhub openlinkhub -"
      ] ++ map (dir: "d ${dataDir}/database/${dir} 0755 openlinkhub openlinkhub -") writeableDatabaseDirs;

      systemd.services.openlinkhub-setup = {
        description = "Prepare OpenLinkHub runtime directory";
        wantedBy = [ "multi-user.target" ];
        before = [ "openlinkhub.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = setupScript;
        };
      };

      systemd.services.openlinkhub = {
        description = "OpenLinkHub";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "openlinkhub-setup.service" "systemd-udev-settle.service" ];
        wants = [ "openlinkhub-setup.service" ];
        serviceConfig = {
          User = "openlinkhub";
          Group = "openlinkhub";
          WorkingDirectory = dataDir;
          ExecStart = lib.getExe package;
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
}
