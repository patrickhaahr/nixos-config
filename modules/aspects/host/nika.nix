{ self, inputs, ... }: {
  flake.nixosConfigurations.nika = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.nika ];
  };

  flake.modules.nixos.nika = {
    imports = [
      self.modules.nixos.nika-hardware
      self.modules.nixos.locale-dk
      self.modules.nixos.android-emulator
      self.modules.nixos.blender
      self.modules.nixos.cascadia-code
      self.modules.nixos.containers
      self.modules.nixos.computer-use-linux
      self.modules.nixos.fritzing
      self.modules.nixos.doas

      self.modules.nixos.screenshot-ocr
      self.modules.nixos.home-manager
      self.modules.nixos.helium
      self.modules.nixos.hex
      self.modules.nixos.lanzaboote
      self.modules.nixos.kdenlive
      self.modules.nixos.nix-ld
      self.modules.nixos.nix-features
      self.modules.nixos.nix-maintenance
      self.modules.nixos.binary-cache
      self.modules.nixos.binary-cache-builder
      self.modules.nixos.canary
      self.modules.nixos.identity-ph-desktop
      self.modules.nixos.identity-ph-cliproxyapi
      self.modules.nixos.kaigen-studio
      self.modules.nixos.learnharness
      self.modules.nixos.nautilus
      self.modules.nixos.openhome
      self.modules.nixos.openlinkhub
      self.modules.nixos.opentabletdriver
      self.modules.nixos.obs
      self.modules.nixos.obsidian
      self.modules.nixos.openssh
      self.modules.nixos.pavucontrol
      self.modules.nixos.tailscale
      self.modules.nixos.niri
      self.modules.nixos.mpv

      self.modules.nixos.signal
      self.modules.nixos.spicetify
      self.modules.nixos.steam
      self.modules.nixos.sunshine
      self.modules.nixos.t3code
      self.modules.nixos.wl-clipboard
      self.modules.nixos.zed
      self.modules.nixos.chatgpt
      self.modules.nixos.claude-desktop
      self.modules.nixos.artcraft
      self.modules.nixos.rpi-imager
    ];

    networking.networkmanager.enable = true;
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
    services = {
      openhome = {
        enable = true;
        automations.enable = true;
      };
    };

    networking.hostName = "nika";
    canary = {
      user = "ph";
      sopsFile = ../../../secrets/nika.yaml;
    };

    home-manager.users.ph.imports = [
      self.modules.homeManager.spicetify
      self.modules.homeManager.openhome
    ];
    system.stateVersion = "25.11";
  };
}
