{ self, ... }:
let
  userName = "ph";
in
{
  flake.modules.nixos.identity-ph-headless = { pkgs, ... }: {
    imports = [ self.modules.nixos.identity-ph ];

    home-manager.users.${userName} = {
      agents.skills.exclude = [ "openhome" ];
      programs = {
        btop.enable = true;
        fastfetch.enable = true;
      };
      home.packages = with pkgs; [
        python3
        sops
      ];
      imports = [
        self.modules.homeManager.agent-tools
        self.modules.homeManager.bun
        self.modules.homeManager.gh
        self.modules.homeManager.git
        self.modules.homeManager.hunk
        self.modules.homeManager.jj
        self.modules.homeManager.nushell
        self.modules.homeManager.openssh
      ];
    };
  };
}
