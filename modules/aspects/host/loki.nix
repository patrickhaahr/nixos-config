{ self, ... }: {
  flake.modules.nixos.loki =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      niriEnabled = config.programs.niri.enable;
    in
    {
      imports = [
        self.modules.nixos.loki-hardware
        self.modules.nixos.home-manager
        self.modules.nixos.nix-features
        self.modules.nixos.nix-maintenance
        self.modules.nixos.identity-ph-laptop
        self.modules.nixos.helium
        self.modules.nixos.openssh
        self.modules.nixos.tailscale
        self.modules.nixos.cascadia-code
        self.modules.nixos.niri
      ];

      networking.hostName = "loki";
      networking.networkmanager.enable = true;
      time.timeZone = "Europe/Copenhagen";
      i18n.defaultLocale = "en_DK.UTF-8";
      services.xserver.xkb.layout = "dk";
      console.keyMap = "dk-latin1";
      nixpkgs.config.allowUnfree = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;
      powerManagement.enable = true;
      services.logind.settings.Login.HandleLidSwitch = "suspend";

      programs.niri.minimalProfile = true;
      services.greetd = {
        enable = true;
        settings.default_session = {
          command =
            if niriEnabled then
              lib.getExe' config.programs.niri.package "niri-session"
            else
              "${pkgs.niri}/bin/niri-session";
          user = "ph";
        };
      };

      system.stateVersion = "25.11";
    };
}
