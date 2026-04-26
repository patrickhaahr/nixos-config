{ inputs, ... }: {
  flake.modules.nixos.workstation = { pkgs, ... }: {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    networking.networkmanager.enable = true;
    time.timeZone = "Europe/Copenhagen";
    i18n.defaultLocale = "en_DK.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "da_DK.UTF-8";
      LC_IDENTIFICATION = "da_DK.UTF-8";
      LC_MEASUREMENT = "da_DK.UTF-8";
      LC_MONETARY = "da_DK.UTF-8";
      LC_NAME = "da_DK.UTF-8";
      LC_NUMERIC = "da_DK.UTF-8";
      LC_PAPER = "da_DK.UTF-8";
      LC_TELEPHONE = "da_DK.UTF-8";
      LC_TIME = "da_DK.UTF-8";
    };
    services.xserver.xkb = {
      layout = "dk";
      variant = "";
    };
    console.keyMap = "dk-latin1";
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [
      openssh
      cascadia-code
      nodejs
      bun
      nushell
      bitwarden-cli
      fzf
      yazi
      wl-clipboard
      fastfetch
      neovim
      starship
      carapace
      nautilus
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
      opencode
    ];
    services.greetd.enable = true;
    services.greetd.settings.default_session.command = "${pkgs.niri}/bin/niri-session";
    services.greetd.settings.default_session.user = "ph";
  };
}
