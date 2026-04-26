{ ... }: {
  flake.modules.nixos.tester-hardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "uas" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];
    fileSystems."/" = {
      device = "/dev/mapper/luks-4b887d46-af7b-4153-9105-3f9286df520d";
      fsType = "ext4";
    };
    boot.initrd.luks.devices."luks-4b887d46-af7b-4153-9105-3f9286df520d".device =
      "/dev/disk/by-uuid/4b887d46-af7b-4153-9105-3f9286df520d";
    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/6348-8E7C";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
    swapDevices = [ ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
