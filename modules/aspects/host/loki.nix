{ self, ... }: {
  flake.modules.nixos.loki =
    { pkgs, ... }:
    {
      imports = [
        self.modules.nixos.loki-hardware
        self.modules.nixos.doas
        self.modules.nixos.home-manager
        self.modules.nixos.nix-features
        self.modules.nixos.nix-maintenance
        self.modules.nixos.binary-cache
        self.modules.nixos.identity-ph-laptop
        self.modules.nixos.helium
        self.modules.nixos.openssh
        self.modules.nixos.tailscale
        self.modules.nixos.cascadia-code
        self.modules.nixos.mpv
        self.modules.nixos.niri
        self.modules.nixos.screenshot-ocr
        self.modules.nixos.signal
      ];

      networking.hostName = "loki";
      networking.networkmanager.enable = true;
      time.timeZone = "Europe/Copenhagen";
      i18n.defaultLocale = "en_DK.UTF-8";
      services = {
        xserver.xkb.layout = "dk";
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
      console.keyMap = "dk-latin1";
      nixpkgs.config.allowUnfree = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };

      security.rtkit.enable = true;
      powerManagement.enable = true;

      programs.signal.autostart = false;

      system.stateVersion = "25.11";
    };
}
