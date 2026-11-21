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

        kernelModules = [
          "kvm-amd"
          "sd_mod"
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
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
