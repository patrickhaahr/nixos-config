{ inputs, ... }: {
  flake.modules.homeManager.herdr = { pkgs, lib, ... }: {
    home.packages = [ inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default ];

    home.activation.herdrConfig = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -f "$HOME/.config/herdr/config.toml" ]]; then
        mkdir -p "$HOME/.config/herdr"
        printf '%s\n' \
          '[terminal]' \
          'default_shell = "nu"' \
          '[update]' \
          'version_check = false' \
          '[ui]' \
          'sidebar_width = 20' \
          '[ui.toast]' \
          'delivery = "system"' \
          > "$HOME/.config/herdr/config.toml"
      fi
    '';
  };
}
