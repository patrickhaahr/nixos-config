_: {
  flake.modules.homeManager.nvf = { pkgs, lib, ... }: {
    programs.nvf = {
      enable = true;
      settings = {
        vim = {
          searchCase = "smart";
          clipboard = {
            enable = true;
            providers.wl-copy.enable = true;
            registers = "unnamedplus";
          };
          extraPlugins = {
            fff = {
              package = pkgs.vimPlugins."fff-nvim";
              setup = ''
                require("fff").setup({
                  keymaps = {
                    close = { "<C-c>", "<Esc>" },
                    move_up = { "<Up>", "<C-k>" },
                    move_down = { "<Down>", "<C-j>" },
                  },
                  git = {
                    status_text_color = true,
                  },
                })
              '';
            };
            mini-cmdline = {
              package = pkgs.vimPlugins.mini-cmdline;
              setup = ''
                require("mini.cmdline").setup({
                  autocorrect = { enable = true },
                })
              '';
            };
            supermaven = {
              package = pkgs.vimPlugins.supermaven-nvim;
              setup = ''
                require("supermaven-nvim").setup({})
              '';
            };
          };
          autocmds = [
            {
              event = [ "TextYankPost" ];
              desc = "Highlight when yanking (copying) text";
              callback = lib.generators.mkLuaInline ''
                function()
                  vim.hl.on_yank()
                end
              '';
            }
          ];
          diagnostics = {
            enable = true;
            config.virtual_text = true;
          };
          lsp = {
            enable = true;
            mappings.goToDefinition = "gd";
          };
          globals.netrw_banner = 0;
          options = {
            tabstop = 4;
            softtabstop = 4;
            shiftwidth = 4;
            expandtab = true;
            wrap = true;
            linebreak = true;
            smartindent = true;
            inccommand = "split";
            laststatus = 3;
            undofile = true;
            completeopt = "menuone,noselect,fuzzy,nosort";
            scrolloff = 8;
            colorcolumn = "100";
            showbreak = "↪ ";
          };
          keymaps = [
            {
              key = "p";
              mode = "x";
              action = ''"_dP'';
              desc = "Paste over selection without losing yanked text";
            }
            {
              key = "<leader>d";
              mode = [
                "n"
                "v"
              ];
              action = ''"_d'';
              desc = "Delete without yanking";
            }
            {
              key = "<Esc>";
              mode = "n";
              action = ":nohl<CR>";
              desc = "Clear search highlighting";
            }
            {
              key = "J";
              mode = "v";
              action = ":m '>+1<CR>gv=gv";
              desc = "moves lines down in visual selection";
            }
            {
              key = "K";
              mode = "v";
              action = ":m '<-2<CR>gv=gv";
              desc = "moves lines up in visual selection";
            }
            {
              key = "<";
              mode = "v";
              action = "<gv";
              desc = "Unindent and keep selection";
            }
            {
              key = ">";
              mode = "v";
              action = ">gv";
              desc = "Indent and keep selection";
            }
            {
              key = "J";
              mode = "n";
              action = "mzJ`z";
              desc = "Join lines without moving cursor";
            }
            {
              key = "<C-d>";
              mode = "n";
              action = "<C-d>zz";
              desc = "move down in buffer with cursor centered";
            }
            {
              key = "<C-u>";
              mode = "n";
              action = "<C-u>zz";
              desc = "move up in buffer with cursor centered";
            }
            {
              key = "n";
              mode = "n";
              action = "nzzzv";
              desc = "Next search result cursor centered";
            }
            {
              key = "N";
              mode = "n";
              action = "Nzzzv";
              desc = "Previous search result cursor centered";
            }
            {
              key = "<leader>s";
              mode = "n";
              action = '':%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>'';
              desc = "Replace word cursor is on globally";
            }
            {
              key = "<leader>X";
              mode = "n";
              action = "<cmd>!chmod +x %<CR>";
              desc = "makes file executable";
            }
            {
              key = "<leader>re";
              mode = "n";
              action = "<cmd>restart<cr>";
              desc = "Restart config :restart)";
            }
            {
              key = "<leader>fmt";
              mode = "n";
              lua = true;
              action = "vim.lsp.buf.format";
              desc = "Format Local buffer";
            }
            {
              key = "df";
              mode = "n";
              lua = true;
              action = "vim.diagnostic.open_float";
              desc = "Show line diagnostics";
            }
            {
              key = "<leader>u";
              mode = "n";
              action = "<cmd>UndotreeToggle<CR>";
              desc = "Toggle Builtin Undotree";
            }
            {
              key = "<leader>e";
              mode = "n";
              lua = true;
              action = ''function() require("mini.files").open() end'';
              desc = "Toggle mini file explorer";
            }
            {
              key = "<leader>-";
              mode = "n";
              lua = true;
              action = ''function() local MiniFiles = require("mini.files"); MiniFiles.open(vim.api.nvim_buf_get_name(0), false); MiniFiles.reveal_cwd() end'';
              desc = "Toggle into currently opened file";
            }
            {
              key = "<leader>ff";
              mode = "n";
              lua = true;
              action = ''function() require("fff").find_files() end'';
              desc = "FFF File Picker";
            }
            {
              key = "<leader>fg";
              mode = "n";
              lua = true;
              action = ''function() require("fff").live_grep({ query = vim.fn.expand("<cword>"), grep = { modes = { "fuzzy", "plain" } } }) end'';
              desc = "FFF Grep word/Search word";
            }
            {
              key = "<leader>nix";
              mode = "n";
              lua = true;
              action = ''function() require("fff").find_files_in_dir(vim.fn.expand("~/nixos-config")) end'';
              desc = "Find files in ~/nixos-config";
            }
            {
              key = "<leader>vh";
              mode = "n";
              lua = true;
              action = ''function() require("mini.pick").builtin.help() end'';
              desc = "Mini Help";
            }
            {
              key = "<leader>xx";
              mode = "n";
              lua = true;
              action = ''function() require("mini.extra").pickers.diagnostic() end'';
              desc = "Mini Picker Diagnostics";
            }
            {
              key = "<leader>pk";
              mode = "n";
              lua = true;
              action = ''function() require("mini.extra").pickers.keymaps() end'';
              desc = "Search keymaps";
            }
            {
              key = "<leader>gg";
              mode = "n";
              action = "<cmd>tabnew | Git | only<cr>";
              desc = "Fugitive Full Page New Tab";
            }
            {
              key = "<leader>gd";
              mode = "n";
              action = "<cmd>Gvdiffsplit<CR>";
              desc = "Git diff split";
            }
          ];
          treesitter.enable = true;
          languages = {
            enableTreesitter = true;
            astro.enable = true;
            bash.enable = true;
            csharp.enable = true;
            go.enable = true;
            nix.enable = true;
            python.enable = true;
            rust.enable = true;
            typescript.enable = true;
            css.enable = true;
            docker.enable = true;
            env.enable = true;
            html.enable = true;
            json.enable = true;
            markdown.enable = true;
            sql.enable = true;
            toml.enable = true;
            typst.enable = true;
            yaml.enable = true;
          };
          theme = {
            enable = true;
            name = "catppuccin";
            style = "mocha";
          };
          mini = {
            files = {
              enable = true;
              setupOpts = {
                mappings = {
                  go_in = "<CR>";
                  go_in_plus = "L";
                  go_out = "_";
                  go_out_plus = "H";
                };
              };
            };
            notify = {
              enable = true;
              setupOpts = {
                lsp_progress.enable = false;
                content.format = lib.generators.mkLuaInline ''
                  function(notif)
                    return notif.msg
                  end
                '';
              };
            };
            surround.enable = true;
            pick.enable = true;
            extra.enable = true;
            completion = {
              enable = true;
              setupOpts = {
                lsp_completion.auto_setup = true;
              };
            };
            diff = {
              enable = true;
              setupOpts.source = lib.generators.mkLuaInline ''
                require("mini.diff").gen_source.git({ index = false })
              '';
            };
          };
          git.vim-fugitive.enable = true;
          utility.undotree.enable = true;

          luaConfigRC.core = ''
            vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
            vim.opt.shortmess:append("c")
            vim.opt.isfname:append("@-@")
          '';
          luaConfigPost = ''
            pcall(function()
              require("vim._core.ui2").enable({})
            end)
          '';
        };
      };
    };
  };
}
