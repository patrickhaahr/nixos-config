_: {
  flake.modules.nixos.kuma-hardware =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/hardware/cpu/intel-npu.nix")
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot = {
        initrd = {
          availableKernelModules = [
            "xhci_pci"
            "thunderbolt"
            "nvme"
            "uas"
            "sd_mod"
          ];
          kernelModules = [ ];
          luks.devices = {
            "luks-0297540b-bcab-4f68-a9ed-552dc962faa8".device =
              "/dev/disk/by-uuid/0297540b-bcab-4f68-a9ed-552dc962faa8";
            "luks-0e5e6701-d2d8-47b3-be56-858b04a7453e".device =
              "/dev/disk/by-uuid/0e5e6701-d2d8-47b3-be56-858b04a7453e";
          };
        };
        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];
      };

      fileSystems."/" = {
        device = "/dev/mapper/luks-0e5e6701-d2d8-47b3-be56-858b04a7453e";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/9964-504D";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [
        { device = "/dev/mapper/luks-0297540b-bcab-4f68-a9ed-552dc962faa8"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel = {
        npu.enable = true;
        updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };
    };
}
