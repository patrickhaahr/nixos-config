_: {
  flake.modules.nixos.homelab-librespeed = {
    services.librespeed = {
      enable = true;
      domain = "speedtest.zaza.haahr.me";
      frontend = {
        enable = true;
        pageTitle = "zaza speedtest";
        contactEmail = "traefik@haahr.me";
      };
      settings = {
        # nginx proxies /backend/ to it; keep it off the LAN and tailnet.
        bind_address = "127.0.0.1";
        worker_threads = 1;
      };
    };
  };
}
