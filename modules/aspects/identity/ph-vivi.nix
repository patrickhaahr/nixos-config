_: {
  flake.modules.nixos.identity-ph-vivi = {
    users.users.ph = {
      isNormalUser = true;
      extraGroups = [
        "video"
        "wheel"
      ];
      openssh.authorizedKeys.keyFiles = [ ./ph-vivi.pub ];
    };
    security.sudo.wheelNeedsPassword = false;
  };
}
