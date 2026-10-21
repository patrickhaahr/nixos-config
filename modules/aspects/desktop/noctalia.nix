{ inputs, self, ... }:
let
  wallhavenIds = {
    "3z8k8d.jpg" = "sha256-7uHdZdQTvLT8fA4zpLRmB2J8WngbuaEQK8EhhPomE0o=";
    "4de89j.jpg" = "sha256-wvr5upt/DOyHGvkM9JSagQVZwKnL1pRnz9IfZzg49J0=";
    "7jj6je.jpg" = "sha256-muB1yANHlX0Xp5h2YXsTE3NXBx9ZzU32kdzl96ROEQ0=";
    "e7lrvk.jpg" = "sha256-FWscAvbYPZE5fmVVuorbgzlAm8XLq/Xpk2CeNjyDLbw=";
    "yx3kok.jpg" = "sha256-xvjagplk3eDRfJ+6Jd1+AnG7ZHHggYVkn+D/vbzU0tM=";
    "z82gqy.jpg" = "sha256-0nYK2lW222hJueq9Eo1HC0bPXHe8+Dp6w+hZFHV4vvY=";
    "9d8j98.jpg" = "sha256-c6VVM+gh5WUthqn+kH9AKlXMAOIA8oO82uw2ooFEE60=";
    "9mjoy1.png" = "sha256-EAyUfeGqWuNv+lvi9PVZyGhvv145S99EWgHQDFkacw0=";
    "gwwy5d.jpg" = "sha256-ar7SDnHXhCHXt6MisYwvm6h/Q8rYFJlGKMOTsSdGfr8=";
    "ly2yg2.jpg" = "sha256-D2l7ugRhMC9rdiCGYzRCfOuFAjsmHeg/ypGsnie/Oss=";
    "rqje87.jpg" = "sha256-jWOtQ5RBOadTw9pbmgD4gyoAwYh+MLMFdRqEZndew7g=";
    "vpqpem.png" = "sha256-VyGKgdkoN2hXIxjOtVDJkKhAWNuVDI4GvMFJWThGBEI=";
    "ymz61d.jpg" = "sha256-AmApCq7qu8SpIl9bcMm1SMNpNuTTgjASNhLhQf5rjTs=";
    "zm825o.jpg" = "sha256-ujBiLsCepI2RHh5h1hzw3i+F94ACOFhzgFfZWGmRz9I=";
    "zp9joo.png" = "sha256-h003lpgaufpr/5LaXzVZX0mVRsgK0360wRAGojhubng=";
    "q21ezq.jpg" = "sha256-4ONyu3T/+wHAp8Is8uQL0tU0lipW3LhMGGuMoVowyCA=";
    "l35pxl.jpg" = "sha256-LUJOEoPNcNNJ0pFdPDbJmRmzGobPH3kKzJ3wU1ZxGfE=";
  };
in
{
  flake.modules.homeManager.noctalia-wallpapers =
    { pkgs, ... }:
    {
      home.file.".local/share/noctalia/wallpapers".source = pkgs.linkFarm "wallhaven-wallpapers" (
        builtins.attrValues (
          builtins.mapAttrs (file: hash: {
            name = "wallhaven-${file}";
            path = pkgs.fetchurl {
              url = "https://w.wallhaven.cc/full/${builtins.substring 0 2 file}/wallhaven-${file}";
              inherit hash;
            };
          }) wallhavenIds
        )
      );
    };

  flake.modules.homeManager.noctalia = { pkgs, ... }: {
    imports = [ self.modules.homeManager.noctalia-wallpapers ];

    programs.noctalia = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # v5 reads TOML; GUI changes remain writable in ~/.local/state/noctalia.
      # Keep the old v4 JSON files for rollback, but do not load them into v5.
      settings = {
        shell = {
          avatar_path = "${../../../assets/nika.jpeg}";
          clipboard_enabled = false;
          panel = {
            launcher_position = "center";
            control_center_placement = "attached";
          };
        };
        theme = {
          mode = "dark";
          source = "wallpaper";
          builtin = "Gruvbox";
          templates = {
            enable_builtin_templates = false;
            enable_community_templates = false;
          };
        };
        bar.main = {
          position = "top";
          thickness = 30;
          margin_ends = 0;
          margin_edge = 0;
          radius = 0;
          shadow = false;
          capsule = false;
          reserve_space = true;
          start = [
            "control-center"
            "workspaces"
          ];
          center = [ ];
          end = [
            "notifications"
            "power_profile"
            "volume"
            "battery"
            "microphone"
            "keyboard_layout"
            "clock"
            "tray"
          ];
        };
        widget = {
          control-center = {
            glyph = "brand-nixos";
            color = "tertiary";
          };
          workspaces = {
            show_labels = false;
            show_icons = false;
            hide_when_empty = true;
            max_label_chars = 2;
          };
          volume.show_label = false;
          microphone = {
            type = "volume";
            device = "input";
            show_label = false;
          };
          keyboard_layout.hide_when_single_layout = true;
          clock = {
            format = "{:%H:%M %a, %b %d}";
            color = "primary";
          };
        };
        brightness.enable_ddcutil = true;
        nightlight = {
          enabled = true;
          force = true;
          temperature_day = 6500;
          temperature_night = 3000;
        };
        location = {
          auto_locate = false;
          address = "Copenhagen, Denmark";
        };
        weather = {
          enabled = true;
          unit = "celsius";
        };
        notification.layer = "overlay";
        osd = {
          position = "bottom_center";
          hide_delay_ms = 3000;
        };
        lockscreen.lock_before_suspend = true;
        wallpaper = {
          directory = "/home/ph/.local/share/noctalia/wallpapers";
          automation = {
            enabled = true;
            interval_seconds = 1800;
            order = "random";
          };
        };
      };
    };
  };

  perSystem = { system, ... }: {
    packages.noctalia = inputs.noctalia.packages.${system}.default;
  };
}
