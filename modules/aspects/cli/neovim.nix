{ ... }: {
  flake.modules.homeManager.neovim = {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withPython3 = false;
      withRuby = false;

      initLua = ''
        vim.opt.clipboard = "unnamedplus"
      '';
    };
  };
}
