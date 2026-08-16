{ inputs, ... }: {
  flake.modules.homeManager.herdr = { pkgs, ... }: {
    home.packages = [ inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    xdg.configFile."herdr/config.toml".text = ''
      [terminal]
      default_shell = "nu"

      [ui.toast]
      delivery = "system"
    '';
  };
}
