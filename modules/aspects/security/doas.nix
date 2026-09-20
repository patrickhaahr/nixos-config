_: {
  flake.modules.nixos.doas = {
    security = {
      sudo.enable = false;
      doas.enable = true;
      polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel") &&
              (action.id == "org.freedesktop.login1.power-off" ||
               action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
               action.id == "org.freedesktop.login1.reboot" ||
               action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
               action.id == "org.freedesktop.login1.halt" ||
               action.id == "org.freedesktop.login1.halt-multiple-sessions")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
    system.tools.nixos-rebuild.enableRun0Elevation = true;
  };
}
