{ ... }: {
  flake.modules.homeManager.steam-hm = {
    home.file.".local/share/Steam/steam_dev.cfg".text = ''
      @nClientDownloadEnableHTTP2PlatformLinux 0
      @fDownloadRateImprovementToAddAnotherConnection 1.1
      @cMaxInitialDownloadSources 15
    '';
  };
}
