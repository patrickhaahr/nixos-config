{ inputs, ... }: {
  flake.modules.nixos.codex-desktop = {
    imports = [ inputs.codex-desktop-linux.nixosModules.default ];
    programs.codexDesktopLinux.enable = true;
  };
}
