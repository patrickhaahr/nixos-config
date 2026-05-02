{ ... }: {
  flake.modules.nixos.sunshine = {
    services.sunshine = {
      enable = true;
      autoStart = false;
      openFirewall = true;
    };
  };
}
