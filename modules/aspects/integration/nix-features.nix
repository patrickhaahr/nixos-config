{ ... }: {
  flake.modules.nixos.nix-features = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
