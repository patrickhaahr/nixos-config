{ self, ... }:
let
  userName = "ph";
in {
  flake.modules.nixos.identity-ph-headless = {
    imports = [ self.modules.nixos.identity-ph ];

    home-manager.users.${userName}.imports = [
      self.modules.homeManager.direnv
      self.modules.homeManager.btop
      self.modules.homeManager.fastfetch
      self.modules.homeManager.gh
      self.modules.homeManager.git
      self.modules.homeManager.jj
      self.modules.homeManager.nushell
      self.modules.homeManager.nvf
      self.modules.homeManager.opencode
      self.modules.homeManager.openssh
      self.modules.homeManager.pi
      self.modules.homeManager.sops
      self.modules.homeManager.typst
    ];
  };
}
