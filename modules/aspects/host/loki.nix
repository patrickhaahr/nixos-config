{ self, inputs, ... }: {
  flake.nixosConfigurations.loki = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.loki ];
  };

  flake.modules.nixos.loki = {
    imports = [
      self.modules.nixos.loki-hardware
      self.modules.nixos.laptop
      self.modules.nixos.locale-dk
      self.modules.nixos.doas
      self.modules.nixos.home-manager
      self.modules.nixos.nix-features
      self.modules.nixos.nix-maintenance
      self.modules.nixos.binary-cache
      self.modules.nixos.identity-ph-graphical
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

    programs.signal.autostart = false;

    system.stateVersion = "25.11";
  };
}
