{ self, ... }:
{
  flake.modules.homeManager.agent-tools =
    { pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        agent-shell
        fd
        ffmpeg
        file
        jq
        less
        ripgrep
        sqlite
        tree
        unzip
      ];

      home.packages = with pkgs; [
        bc
        binutils
        openssl
        pigz
        psmisc
        unixtools.xxd
        zip
      ];
    };
}
