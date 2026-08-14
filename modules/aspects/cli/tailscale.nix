_: {
  flake.modules.nixos.tailscale = {
    services.tailscale.enable = true;
    systemd.services.tailscaled.environment.TS_NO_LOGS_NO_SUPPORT = "true";
  };
}
