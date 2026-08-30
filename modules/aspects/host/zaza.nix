{ self, ... }: {
  flake.modules.nixos.zaza = { pkgs, ... }: {
    imports = [
      self.modules.nixos.zaza-hardware
      self.modules.nixos.doas
      self.modules.nixos.nix-features
      self.modules.nixos.home-manager
      self.modules.nixos.homelab-excalidraw
      self.modules.nixos.homelab-executor
      self.modules.nixos.homelab-firecrawl
      # self.modules.nixos.homelab-grafana
      # self.modules.nixos.homelab-honcho
      self.modules.nixos.homelab-librespeed
      # self.modules.nixos.homelab-llamacpp
      # self.modules.nixos.homelab-openconcho
      # self.modules.nixos.homelab-prometheus
      self.modules.nixos.homelab-searxng
      self.modules.nixos.homelab-traefik
      # self.modules.nixos.homelab-wazuh
      self.modules.nixos.identity-ph-headless
      self.modules.nixos.agent-hermes-host
      self.modules.nixos.openhome
      self.modules.nixos.k3s
      self.modules.nixos.k3s-nvidia
      self.modules.nixos.nix-maintenance
      self.modules.nixos.openssh
      self.modules.nixos.sops
      self.modules.nixos.tailscale
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      kernelPackages = pkgs.linuxPackages_latest;
    };
    networking = {
      hostName = "zaza";
      networkmanager.enable = true;
      # Hermes dashboard, reachable only over tailscale.
      firewall.interfaces."tailscale0".allowedTCPPorts = [ 9119 ];
    };
    users.users.ph.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9QHax4U5wGvtHs+J12lX6VwSfRAboJCAXVuUiNnM0+ nika-to-zaza"
    ];
    users.users.ph.extraGroups = [ "networkmanager" ];
    # OpenHome CLI for Hermes; the Nika-only speaker lifecycle automations
    # stay disabled.
    services.openhome.enable = true;
    time.timeZone = "Europe/Copenhagen";
    i18n.defaultLocale = "en_DK.UTF-8";
    console.keyMap = "dk-latin1";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "25.11";
  };
}
