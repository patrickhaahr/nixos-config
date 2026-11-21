_: {
  flake.modules.nixos.identity-ph-vivi = {
    users.users.ph = {
      isNormalUser = true;
      extraGroups = [
        "video"
        "wheel"
      ];
      openssh.authorizedKeys.keyFiles = [
        ./ph-vivi.pub

        ../../../secrets/hermes/hosts.pub
      ];
    };
    security.sudo.wheelNeedsPassword = false;
  };
}
