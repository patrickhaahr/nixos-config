{ ... }: {
  flake.modules.homeManager.ghostty = {
    programs.ghostty = {
      enable = true;
      clearDefaultKeybinds = true;
      settings = {
        "font-family" = "Cascadia Code";
        "font-size" = 12;
        "window-decoration" = "none";
        "gtk-tabs-location" = "bottom";
        "gtk-toolbar-style" = "flat";
        "background-opacity" = 0.65;
        "background-opacity-cells" = true;
        "unfocused-split-opacity" = 1;
        "mouse-hide-while-typing" = true;
        "copy-on-select" = "clipboard";
        "window-save-state" = "always";
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
  };
}
