{ self, ... }: {
  flake.modules.nixos.kuma = {
    imports = [
      self.modules.nixos.kuma-hardware
      self.modules.nixos.laptop
      self.modules.nixos.locale-dk
      self.modules.nixos.containers
      self.modules.nixos.doas
      self.modules.nixos.home-manager
      self.modules.nixos.nix-features
      self.modules.nixos.nix-ld
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
      self.modules.nixos.virtual-machines
      self.modules.nixos.wl-clipboard
      self.modules.nixos.zed
    ];

    networking.hostName = "kuma";
    home-manager.users.ph.imports = [ self.modules.homeManager.agent-browser ];
    networking.networkmanager.enable = true;

    programs.signal.autostart = false;

    system.stateVersion = "25.11";
  };
}
