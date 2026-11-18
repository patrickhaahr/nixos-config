{ inputs, ... }:
{
  flake.modules.nixos.vivi-hardware = { pkgs, ... }: {
    imports = [ inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base ];

    boot.loader.raspberry-pi.bootloader = "uboot";

    # The default 512 MiB CMA reservation fails on Vivi's 2 GB Pi 4.
    hardware.raspberry-pi.config.all.dt-overlays.vc4-kms-v3d.params.cma-128.enable = true;

    # rpicam-apps expects the Raspberry Pi OS alias for the Pi 4 CMA heap.
    services.udev.extraRules = ''
      SUBSYSTEM=="dma_heap", KERNEL=="default_cma_region", SYMLINK+="dma_heap/vidbuf_cached"
    '';
    environment.systemPackages = [ pkgs.rpi.rpicam-apps ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
    fileSystems."/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
  };
}
