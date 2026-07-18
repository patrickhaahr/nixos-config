{ ... }: {
  flake.modules.nixos.loki-hardware = { config, lib, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "uas" "sd_mod" "sdhci_pci" ];
    boot.kernelModules = [ "kvm-intel" ];

    fileSystems."/" = {
      device = "/dev/mapper/luks-087f972d-c785-4be1-973a-98ef76c56559";
      fsType = "ext4";
    };

    boot.initrd.luks.devices."luks-087f972d-c785-4be1-973a-98ef76c56559".device =
      "/dev/disk/by-uuid/087f972d-c785-4be1-973a-98ef76c56559";

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/F339-7902";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

    swapDevices = [
      { device = "/dev/mapper/luks-4af899f4-6e52-42ac-8fbf-b81b85596091"; }
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
