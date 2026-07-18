_: {
  flake.modules.homeManager.ghostty = { config, ... }: {
    home.file.".config/ghostty/gtk.css".text = ''
      toolbarview > .bottom-bar,
      toolbarview > .bottom-bar:backdrop,
      toolbarview > .bottom-bar > windowhandle,
      toolbarview > .bottom-bar:backdrop > windowhandle,
      toolbarview > .bottom-bar > windowhandle > box,
      toolbarview > .bottom-bar:backdrop > windowhandle > box {
        background-color: #181825;
        color: #bac2de;
        border: none;
        box-shadow: none;
        outline: none;
        filter: none;
        opacity: 1;
        transition: none;
      }

      toolbarview > .bottom-bar tabbar,
      toolbarview > .bottom-bar tabbar:backdrop,
      toolbarview > .bottom-bar tabbar > revealer > .box,
      toolbarview > .bottom-bar tabbar > revealer > .box:backdrop,
      toolbarview > .bottom-bar tabbar .start-action,
      toolbarview > .bottom-bar tabbar .start-action:backdrop,
      toolbarview > .bottom-bar tabbar .end-action,
      toolbarview > .bottom-bar tabbar .end-action:backdrop {
        background-color: transparent;
        color: #bac2de;
        border: none;
        box-shadow: none;
        outline: none;
        filter: none;
        opacity: 1;
        transition: none;
      }

      toolbarview > .bottom-bar tabbar > revealer > .box {
        padding: 0 2px;
      }

      toolbarview > .bottom-bar tabbar tabbox,
      toolbarview > .bottom-bar tabbar tabbox:backdrop {
        min-height: 0;
        padding-top: 2px;
        padding-bottom: 2px;
        border: none;
        border-radius: 0;
        border-spacing: 2px;
        box-shadow: none;
        outline: none;
      }

      toolbarview > .bottom-bar tabbar tab,
      toolbarview > .bottom-bar tabbar tab:backdrop,
      toolbarview > .bottom-bar tabbar tab:focus,
      toolbarview > .bottom-bar tabbar tab:selected:backdrop,
      toolbarview > .bottom-bar tabbar tabbox.single-tab tab,
      toolbarview > .bottom-bar tabbar tabbox.single-tab tab:backdrop {
        min-height: 24px;
        margin: 0;
        padding: 0;
        border: none;
        border-radius: 2px;
        background-color: transparent;
        color: #bac2de;
        box-shadow: none;
        outline: none;
        transition: none;
      }

      toolbarview > .bottom-bar tabbar tab:hover,
      toolbarview > .bottom-bar tabbar tab:selected,
      toolbarview > .bottom-bar tabbar tab:selected:hover,
      toolbarview > .bottom-bar tabbar tabbox.single-tab tab:selected {
        background-color: #313244;
        box-shadow: none;
      }

      toolbarview > .bottom-bar tabbar tab .tab-title,
      toolbarview > .bottom-bar tabbar tab .tab-title:backdrop {
        padding: 0 5px;
        font-size: 0.76em;
        font-weight: 500;
        color: #bac2de;
      }

      toolbarview > .bottom-bar tabbar tab:selected .tab-title,
      toolbarview > .bottom-bar tabbar tab:selected .tab-title:backdrop {
        color: #89b4fa;
      }

      toolbarview > .bottom-bar tabbar tab button.tab-close-button,
      toolbarview > .bottom-bar tabbar tab button.tab-close-button:backdrop {
        min-width: 12px;
        min-height: 24px;
        margin: 0 3px 0 0;
        padding: 0;
        border-radius: 2px;
        background-color: transparent;
        color: #9399b2;
        box-shadow: none;
        outline: none;
        transition: none;
      }

      toolbarview > .bottom-bar tabbar tab:selected button.tab-close-button,
      toolbarview > .bottom-bar tabbar tab:selected button.tab-close-button:backdrop,
      toolbarview > .bottom-bar tabbar tab button.tab-close-button:hover {
        color: #89b4fa;
      }
    '';

    programs.ghostty = {
      enable = true;
      systemd.enable = true;
      clearDefaultKeybinds = true;
      settings = {
        "font-family" = "Cascadia Code";
        "font-size" = 18;
        "window-decoration" = "none";
        "gtk-tabs-location" = "bottom";
        "window-show-tab-bar" = "always";
        "gtk-toolbar-style" = "flat";
        "gtk-wide-tabs" = false;
        "gtk-custom-css" = "~/.config/ghostty/gtk.css";
        "background-opacity" = 0.75;
        "background-opacity-cells" = true;
        "unfocused-split-opacity" = 1;
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        "cursor-color" = "#f5e0dc";
        "cursor-text" = "#1e1e2e";
        "selection-background" = "#585b70";
        "selection-foreground" = "#cdd6f4";
        palette = [
          "0=#45475a"
          "1=#f38ba8"
          "2=#a6e3a1"
          "3=#f9e2af"
          "4=#89b4fa"
          "5=#f5c2e7"
          "6=#94e2d5"
          "7=#a6adc8"
          "8=#585b70"
          "9=#f37799"
          "10=#89d88b"
          "11=#ebd391"
          "12=#74a8fc"
          "13=#f2aede"
          "14=#6bd7ca"
          "15=#bac2de"
        ];
        "mouse-hide-while-typing" = true;
        "copy-on-select" = "clipboard";
        "window-save-state" = "always";
        "quit-after-last-window-closed" = false;
        "confirm-close-surface" = false;
        keybind = [
          "copy=copy_to_clipboard:mixed"
          "paste=paste_from_clipboard"
          "ctrl+shift+c=copy_to_clipboard:mixed"
          "ctrl+shift+v=paste_from_clipboard"
          "½>c=new_tab"
          "½>x=close_surface"
          "½>1=goto_tab:1"
          "½>2=goto_tab:2"
          "½>3=goto_tab:3"
          "½>4=goto_tab:4"
          "½>5=goto_tab:5"
          "½>6=goto_tab:6"
          "½>7=goto_tab:7"
          "½>8=goto_tab:8"
          "½>9=goto_tab:9"
          "½>0=last_tab"
          "½>p=previous_tab"
          "½>n=next_tab"
          "½>h=goto_split:left"
          "½>j=goto_split:bottom"
          "½>k=goto_split:top"
          "½>l=goto_split:right"
          "alt+h=goto_split:left"
          "alt+j=goto_split:bottom"
          "alt+k=goto_split:top"
          "alt+l=goto_split:right"
          "½>v=new_split:right"
          "½>s=new_split:down"
          "½>z=toggle_split_zoom"
          "½>H=resize_split:left,60"
          "½>J=resize_split:down,60"
          "½>K=resize_split:up,60"
          "½>L=resize_split:right,60"
          "½>r=reload_config"
        ];
      };
    };

    xdg.configFile."systemd/user/default.target.wants/app-com.mitchellh.ghostty.service".source =
      config.xdg.configFile."systemd/user/app-com.mitchellh.ghostty.service".source;
  };
}
