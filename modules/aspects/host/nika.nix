{ self, inputs, ... }: {
  flake.modules.nixos.nika = { lib, pkgs, ... }: {
    imports = [
      self.modules.nixos.nika-hardware
      self.modules.nixos.audio-output
      self.modules.nixos.containers
      self.modules.nixos.doas
      #self.modules.nixos.hacking
      self.modules.nixos.screenshot-ocr
      self.modules.nixos.home-manager
      self.modules.nixos.helium
      self.modules.nixos.lanzaboote
      self.modules.nixos.nix-maintenance
      self.modules.nixos.identity-ph-desktop
      self.modules.nixos.handy
      self.modules.nixos.openhome
      self.modules.nixos.openlinkhub
      self.modules.nixos.openssh
      self.modules.nixos.tailscale
      self.modules.nixos.niri
      self.modules.nixos.poweroff-scheduler
      self.modules.nixos.signal
      self.modules.nixos.steam
      self.modules.nixos.sunshine
      self.modules.nixos."niri-dp1-1080p"
      self.modules.nixos.workstation
    ];

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
    system.stateVersion = "25.11";
  };
}
