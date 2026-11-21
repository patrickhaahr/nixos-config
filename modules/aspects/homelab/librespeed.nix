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

        bind_address = "127.0.0.1";
        worker_threads = 1;
      };
    };
  };
}
