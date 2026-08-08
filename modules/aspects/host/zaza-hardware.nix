_: {
  flake.modules.nixos.zaza-hardware =
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
      ];
      boot = {
        initrd = {
          availableKernelModules = [
            "xhci_pci"
            "ahci"
            "usbhid"
            "uas"
            "sd_mod"
          ];
          kernelModules = [ ];
          luks.devices."luks-4b887d46-af7b-4153-9105-3f9286df520d" = {
            device = "/dev/disk/by-uuid/4b887d46-af7b-4153-9105-3f9286df520d";
            crypttabExtraOpts = [ "tpm2-device=auto" ];
          };
        };
        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];
      };
      fileSystems."/" = {
        device = "/dev/mapper/luks-4b887d46-af7b-4153-9105-3f9286df520d";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/6348-8E7C";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
      swapDevices = [
        {
          device = lib.mkForce "/swapfile";
          label = "swapfile";
          size = 8192;
        }
      ];
      networking.interfaces.enp2s0.wakeOnLan = {
        enable = true;
        policy = [ "magic" ];
      };
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
