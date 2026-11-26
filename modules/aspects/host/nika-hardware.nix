{ self, inputs, ... }:
{
  flake.modules.nixos.nika-hardware =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")

        inputs.nixos-raspberrypi.nixosModules.trusted-nix-caches
        self.modules.nixos.desktop-session
        self.modules.nixos.audio-output
      ];
      desktop.outputs = {
        "DP-1".mode = "1920x1080";
        "HDMI-A-1".position = {
          x = 0;
          y = 0;
        };
        "DVI-D-1".enable = false;
      };
      boot = {
        binfmt.emulatedSystems = [ "aarch64-linux" ];
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "thunderbolt"
            "usbhid"
            "uas"
            "sd_mod"
          ];
          kernelModules = [ ];
          luks.devices."luks-1dbf142a-5b0c-430b-a372-846e8c50f8d7".device =
            "/dev/disk/by-uuid/1dbf142a-5b0c-430b-a372-846e8c50f8d7";
        };

        kernelPackages = pkgs.linuxPackages_latest;
        kernelModules = [
          "cp210x"
          "hid_playstation"
          "hidp"
          "ip_tables"
          "iptable_nat"
          "kvm-amd"
          "overlay"
          "sd_mod"
          "uas"
          "uinput"
          "usb_storage"
          "xt_addrtype"
          "xt_comment"
        ];
        extraModulePackages = [ ];
      };
      fileSystems."/" = {
        device = "/dev/mapper/luks-1dbf142a-5b0c-430b-a372-846e8c50f8d7";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/87D0-BE1B";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
      swapDevices = [ ];
      security.lockKernelModules = true;
      services.audio-output = {
        headphones = "alsa_output.usb-SteelSeries_Arctis_Pro_Wireless-00.analog-stereo";
        speaker = "bluez_output.FC_E8_06_72_4E_85.1";
      };
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware = {
        cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        opentabletdriver.enable = true;
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings.LE = {
            MinConnectionInterval = 6;
            MaxConnectionInterval = 12;
            ConnectionLatency = 0;
          };
        };
      };
      systemd.services.whoop-ble-low-latency =
        let
          whoopMac = "CD:D5:1E:35:5D:5A";
          whoopPath = "/org/bluez/hci0/dev_CD_D5_1E_35_5D_5A";
          applyScript = pkgs.writeShellApplication {
            name = "whoop-ble-low-latency";
            runtimeInputs = [
              pkgs.bluez
              pkgs.coreutils
              pkgs.dbus
              pkgs.gawk
            ];
            text = ''
              tighten() {
                local handle
                handle="$(hcitool con | awk -v mac="${whoopMac}" '$0 ~ mac { for (i = 1; i <= NF; i++) if ($i == "handle") print $(i + 1) }')"
                if [[ -n "$handle" ]]; then
                  hcitool lecup --handle "$handle" --min 6 --max 12 --latency 0 --timeout 400 || true
                fi
              }

              tighten
              seen_connected=0
              dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='${whoopPath}'" | while IFS= read -r line; do
                if [[ "$line" == *'string "Connected"'* ]]; then
                  seen_connected=1
                elif ((seen_connected)); then
                  seen_connected=0
                  if [[ "$line" == *'boolean true'* ]]; then
                    (
                      sleep 2
                      tighten
                    ) &
                  fi
                fi
              done
            '';
          };
        in
        {
          description = "Keep WHOOP 4.0 BLE connection interval at 7.5-15 ms";
          after = [ "bluetooth.service" ];
          requires = [ "bluetooth.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = lib.getExe applyScript;
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
    };
}
