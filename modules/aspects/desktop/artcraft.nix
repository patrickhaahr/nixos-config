{ inputs, ... }:
{
  flake.modules.nixos.artcraft =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ inputs.artcraft.overlays.default ];
      environment.systemPackages = with pkgs; [
        filmcraft
        pdfcraft
        photocraft
      ];
    };
}
