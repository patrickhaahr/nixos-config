_: {
  flake.modules.nixos.homelab-hermes-user =
    { pkgs, ... }:
    {
      users.groups.hermes.gid = 990;

      users.users.hermes = {
        description = "Hermes Agent";
        uid = 1001;
        group = "hermes";
        home = "/home/hermes";
        createHome = true;
        isNormalUser = true;
        shell = pkgs.bashInteractive;
        extraGroups = [ "k3s-admin" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMUfyFxXSDBxnLaAKTUVuQ+INsS8C0k83RJ9kkNJM0Y nika-to-hermes"
        ];
      };

      services.openssh.settings.AllowUsers = [ "hermes" ];
    };
}
