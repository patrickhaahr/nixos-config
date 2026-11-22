{ self, ... }:
{
  flake.modules.nixos.steam = {
    hardware.steam-hardware.enable = true;
    programs.steam.enable = true;
    programs.gamescope.enable = true;
    home-manager.sharedModules = [ self.modules.homeManager.steam ];
  };

  flake.modules.homeManager.steam = {
    home.file.".local/share/Steam/steam_dev.cfg".text = ''
      @nClientDownloadEnableHTTP2PlatformLinux 0
      @fDownloadRateImprovementToAddAnotherConnection 1.1
      @cMaxInitialDownloadSources 15
    '';
  };
}
