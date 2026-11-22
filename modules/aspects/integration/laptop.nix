_: {
  flake.modules.nixos.laptop =
    { pkgs, ... }:
    {
      boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = true;
        };
      };

      services = {
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
          wireplumber.enable = true;
        };
        upower.enable = true;
        power-profiles-daemon.enable = true;
        logind.settings.Login.HandleLidSwitch = "suspend";
      };

      security.rtkit.enable = true;
      powerManagement.enable = true;
    };
}
