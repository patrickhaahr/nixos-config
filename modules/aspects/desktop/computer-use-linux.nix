_: {
  flake.modules.nixos.computer-use-linux =
    { lib, pkgs, ... }:
    let
      computer-use-linux = pkgs.rustPlatform.buildRustPackage {
        pname = "computer-use-linux";
        version = "0.4.6-unstable-2026-08-06";

        src = pkgs.fetchFromGitHub {
          owner = "agent-sh";
          repo = "computer-use-linux";
          rev = "4a98c152b6b8b6d088aa28feb218d751e47acc16";
          hash = "sha256-ymswolqQXz4Ln7FJMQ0sI+jeQCzdTR897/7nEv7nc5U=";
        };

        cargoHash = "sha256-ptm4q76Cqb/mR+K8X/MGDLoKt34OdPbfiDpION3jD0Y=";

        # The upstream ydotool probe test requires a short private temporary path,
        # which Nix's sandbox cannot provide.
        doCheck = false;
      };
    in
    {
      environment.systemPackages = [
        computer-use-linux
        pkgs.ydotool
      ];

      users.groups.input = { };

      systemd.user.services.ydotoold = {
        description = "Input automation daemon for computer-use-linux";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe' pkgs.ydotool "ydotoold"} --socket-path=%t/.ydotool_socket";
          Restart = "on-failure";
        };
      };
    };
}
