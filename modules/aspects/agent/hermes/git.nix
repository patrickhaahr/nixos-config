{ self, ... }:
{
  flake.modules.homeManager.agent-hermes = {
    imports = [ self.modules.homeManager.git ];
    programs.gh.enable = true;
  };
}
