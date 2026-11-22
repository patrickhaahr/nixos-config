{ self, ... }:
{
  flake.modules.homeManager.agent-tools =
    { pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        agent-shell
        bash
        direnv
        devenv
        codex
        claude-code
        opencode
        pi
        nvf
        yazi
        herdr
      ];

      programs = {
        fd.enable = true;
        jq.enable = true;
        less.enable = true;
        ripgrep.enable = true;
      };

      home.packages = with pkgs; [
        bc
        binutils
        ffmpeg
        file
        openssl
        pigz
        psmisc
        sqlite
        tree
        unixtools.xxd
        unzip
        zip
      ];
    };
}
