{ self, inputs, ... }: {
  flake.modules.nixos.nika = { config, lib, pkgs, ... }:
    let
      niriEnabled = if builtins.hasAttr "programs" config && builtins.hasAttr "niri" config.programs
        then config.programs.niri.enable
        else false;
    in {
    imports = [
      self.modules.nixos.nika-hardware
      self.modules.nixos.audio-output
      self.modules.nixos.cascadia-code
      self.modules.nixos.containers
      self.modules.nixos.doas
      #self.modules.nixos.hacking
      self.modules.nixos.screenshot-ocr
      self.modules.nixos.home-manager
      self.modules.nixos.helium
      self.modules.nixos.lanzaboote
      self.modules.nixos.nix-features
      self.modules.nixos.nix-maintenance
      self.modules.nixos.ollama
      self.modules.nixos.identity-ph-desktop
      self.modules.nixos.handy
      self.modules.nixos.nautilus
      self.modules.nixos.openhome
      self.modules.nixos.openlinkhub
      self.modules.nixos.openssh
      self.modules.nixos.tailscale
      self.modules.nixos.niri
      self.modules.nixos.poweroff-scheduler
      self.modules.nixos.signal
      self.modules.nixos.steam
      self.modules.nixos.sunshine
      self.modules.nixos.wl-clipboard
      self.modules.nixos.yazi
      self.modules.nixos."niri-dp1-1080p"
    ];

    networking.networkmanager.enable = true;
    time.timeZone = "Europe/Copenhagen";
    i18n.defaultLocale = "en_DK.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "da_DK.UTF-8";
      LC_IDENTIFICATION = "da_DK.UTF-8";
      LC_MEASUREMENT = "da_DK.UTF-8";
      LC_MONETARY = "da_DK.UTF-8";
      LC_NAME = "da_DK.UTF-8";
      LC_NUMERIC = "da_DK.UTF-8";
      LC_PAPER = "da_DK.UTF-8";
      LC_TELEPHONE = "da_DK.UTF-8";
      LC_TIME = "da_DK.UTF-8";
    };
    services.xserver.xkb = {
      layout = "dk";
      variant = "";
    };
    console.keyMap = "dk-latin1";
    nixpkgs.config.allowUnfree = true;

    services.audio-output = {
      enable = true;
      headphones = "alsa_output.usb-SteelSeries_Arctis_Pro_Wireless-00.analog-stereo";
      speaker = "bluez_output.FC_E8_06_72_4E_85.1";
    };

    services.openhome.enable = true;

    boot.kernelPackages = pkgs.linuxPackages_latest;
    # Docker needs these netfilter modules available before kernel module locking kicks in.
    boot.kernelModules = [ "ip_tables" "iptable_nat" "overlay" "xt_addrtype" ];
    security.lockKernelModules = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    networking.hostName = "nika";
    #networking.extraHosts = ''    '';
    home-manager.users.ph.imports = [ self.modules.homeManager.spicetify ];
    programs.handy.autostart = true;
    services.greetd.enable = true;
    services.greetd.settings.default_session.command =
      if niriEnabled
      then lib.getExe' config.programs.niri.package "niri-session"
      else "${pkgs.niri}/bin/niri-session";
    services.greetd.settings.default_session.user = "ph";
    system.stateVersion = "25.11";
  };
}
