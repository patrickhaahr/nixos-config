{ ... }: {
  flake.modules.nixos.nika-hardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "thunderbolt" "usbhid" "uas" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];
    fileSystems."/" = {
      device = "/dev/mapper/luks-1dbf142a-5b0c-430b-a372-846e8c50f8d7";
      fsType = "ext4";
    };
    boot.initrd.luks.devices."luks-1dbf142a-5b0c-430b-a372-846e8c50f8d7".device = "/dev/disk/by-uuid/1dbf142a-5b0c-430b-a372-846e8c50f8d7";
    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/87D0-BE1B";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
    swapDevices = [ ];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
