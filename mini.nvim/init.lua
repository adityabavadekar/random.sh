-- Minimal version of nvim config bundled into single file

-- ORDER IS IMP SO options.lua is kept first

-- OPTIONS (options.lua)
-- LEADER --
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- OPTIONS --
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function()
  -- Sync clipboard between OS and Neovim.
  vim.o.clipboard = 'unnamedplus'
end)
vim.o.breakindent = true -- Save undo history
vim.o.undofile = true -- Disable swapfile and backup files
vim.o.swapfile = false
vim.o.backup = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 200 -- Decrease update time
vim.o.timeoutlen = 300
vim.o.ttimeoutlen = 10
vim.o.splitright = true
vim.o.splitbelow = true
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 2 -- Number of spaces that a <Tab> counts for
vim.opt.shiftwidth = 2 -- Number of spaces to use for each step of (auto)indent
vim.opt.softtabstop = 2 -- Number of spaces to use for each step of <Tab> in insert mode
vim.opt.smartindent = true -- Enable smart indentation
vim.opt.autoindent = true -- Copy indent from current line when starting a new line
vim.o.list = true
vim.opt.termguicolors = true -- Enable 24-bit RGB color
vim.opt.smartcase = true -- Don't ignore case with capitals
vim.opt.grepformat = '%f:%l:%c:%m'
vim.opt.grepprg = 'rg --vimgrep'
vim.opt.ignorecase = true -- Ignore case
vim.opt.listchars = { tab = '  ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split' -- Preview substitutions live, as you type!
vim.o.cursorline = true -- Show which line your cursor is on
vim.o.scrolloff = 10 -- Minimal number of screen lines to keep above and below the cursor.
vim.o.confirm = true
vim.g.loaded_netrw = 1 -- Disable netrw, since we use Telescope and Neo-tree instead
vim.g.loaded_netrwPlugin = 1
vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.expand '~/.local/bin' .. ':' .. vim.fn.expand '~/.local/share/nvim/mason/bin' -- Ensure Neovim sees ~/.local/bin and Mason's bin dir
vim.opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}

-- Folding
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.o.foldlevelstart = 99 -- start with all folds open when entering buffer
-- Tell treesitter to use 'tsx' parser for 'typescriptreact' filetype
vim.treesitter.language.register('tsx', 'typescriptreact')

-- Auto-reload files when they change on disk
vim.o.autoread = true
vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'CursorHoldI', 'FocusGained' }, {
  command = 'checktime',
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim', 'Snacks' },
      },
    },
  },
})

vim.opt.formatoptions:remove { 't' }

vim.lsp.enable 'lua_ls'

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- KEYMAPS (keymaps.lua)

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostics
vim.keymap.set('n', '<leader>Q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>q', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Buffer Diagnostics (Trouble)' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Copy full path of the current file to the system clipboard on Ctrl+T
vim.keymap.set('n', '<C-t>', function()
  local file_path = vim.fn.expand '%:p'
  vim.fn.setreg('+', file_path)
  vim.notify 'Copied file path to clipboard'
end, { desc = 'Copy full path of current file to clipboard' })

-- Keybinds to make split navigation easier.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Copy contents of complete buffer to clipboard
vim.keymap.set('n', '<leader>yy', ':%y+<CR>', { noremap = true, silent = true, desc = 'Yank entire file to clipboard' })

-- Git diff
vim.keymap.set('n', '<leader>gd', '<cmd>Gdiffsplit<CR>', { desc = 'Git Diff Split' })

-- Move code blocks up and down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { silent = true })

-- Open Ouline
vim.keymap.set('n', '<space>k', '<cmd>Outline<CR>', { desc = 'Toggle Outline', silent = true })

-- Go to previous tab
vim.keymap.set('n', 'H', ':tabprevious<CR>', { desc = 'Go to previous tab' })
vim.keymap.set('n', 'L', ':tabnext<CR>', { desc = 'Go to next tab' })

-- To restart the LSP for the current buffer
vim.keymap.set('n', '<leader>lr', vim.cmd.LspRestart, { desc = 'Restart LSP' })

-- Keymaps for saving and quitting
vim.keymap.set('n', '<space>w', '<cmd>wq<CR>', { desc = 'Save and quit', silent = true })

-- Terminal Toggles
-- vim.keymap.set('n', '<A-i>', '<CMD>lua require("FTerm").toggle()<CR>')
-- vim.keymap.set('t', '<A-i>', '<C-\\><C-n><CMD>lua require("FTerm").toggle()<CR>')
vim.keymap.set('n', '<A-i>', '<C-\\><C-n><CMD>lua require("snacks").terminal.toggle()<CR>')
vim.keymap.set('t', '<A-i>', '<C-\\><C-n><CMD>lua require("snacks").terminal.toggle()<CR>')

-- Fast save and quit
vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save file', silent = true })
vim.keymap.set('i', '<C-q>', '<Esc><cmd>wq<CR>', { desc = 'Save and quit', silent = true })

-- Open Telescope colorscheme picker
local function open_colorscheme_picker()
  require('telescope.builtin').colorscheme {
    enable_preview = true,
    prompt_title = 'Colorschemes',
  }
end
vim.keymap.set('n', '<A-k>', open_colorscheme_picker, {
  desc = 'Open Telescope colorscheme picker',
})

-- UTILS (utils.lua)
local M_FROM_UTILS = {}

-- [PRETTIER]
local supported = {
  'css',
  'graphql',
  'handlebars',
  'html',
  'javascript',
  'javascriptreact',
  'json',
  'jsonc',
  'less',
  'markdown',
  'markdown.mdx',
  'scss',
  'typescript',
  'typescriptreact',
  'vue',
  'yaml',
}

--- Checks if a Prettier config file exists for the given context
function M_FROM_UTILS.has_config(ctx)
  vim.fn.system { 'prettier', '--find-config-path', ctx.filename }
  return vim.v.shell_error == 0
end

--- Checks if a parser can be inferred for the given context:
--- * If the filetype is in the supported list, return true
--- * Otherwise, check if a parser can be inferred
function M_FROM_UTILS.has_parser(ctx)
  local ft = vim.bo[ctx.buf].filetype --[[@as string]]
  -- default filetypes are always supported
  if vim.tbl_contains(supported, ft) then return true end
  -- otherwise, check if a parser can be inferred
  local ret = vim.fn.system { 'prettier', '--file-info', ctx.filename }
  ---@type boolean, string?
  local ok, parser = pcall(function() return vim.fn.json_decode(ret).inferredParser end)
  return ok and parser and parser ~= vim.NIL
end

-- Codeforces contest checker

-- INIT (init.lua)
require('lazy').setup({
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'codecompanion' },
  },
  {
    'nvim-mini/mini.indentscope',
    version = false,
    opts = {
      symbol = '│',
    },
  },
  {
    'numToStr/FTerm.nvim',
    keys = {
      { '<A-r>', desc = 'Compile and Run C++' },
    },
    config = function()
      local fterm = require 'FTerm'

      fterm.setup {
        border = 'rounded', -- Rounded edges for a polished look
        blend = 0, -- No transparency (set 10–20 for subtle fade)
        dimensions = {
          height = 0.35, -- 35% of screen height
          width = 1.0, -- Full width
          x = 0.5, -- Center horizontally
          y = 1.0, -- Bottom of the screen
        },
      }

      local function run_with_echo(cmd) fterm.run(cmd) end

      --- compile and run
      local function compile_and_run()
        if vim.bo.filetype ~= 'cpp' then
          vim.notify('Not a C++ file', vim.log.levels.WARN)
          return
        end

        local file = vim.fn.expand '%:p'
        local output = vim.fn.expand 'temp/main'

        local full_cmd = string.format(
          [[ clear && g++ -std=c++17 -O2 -Wall -Wextra -Wshadow -Wconversion -DLOCAL -o "%s" "%s" && echo -e "\n\033[1;32m--> [ SUCCESS ] running: ./%s\033[0m\n" && ./"%s" || echo -e "\n\033[1;31m--> [ FAILED ]\033[0m\n" ]],
          output,
          file,
          output,
          output
        )

        run_with_echo(full_cmd)
      end

      vim.keymap.set('n', '<A-y>', compile_and_run, { desc = 'Compile and run current C++ file' })
    end,
  },
  {
    'nvim-tree/nvim-web-devicons',
    config = function()
      require('nvim-web-devicons').setup {
        default = true,
        override = {
          lua = {
            icon = '',
            color = '#51a0cf',
            name = 'Lua',
          },
          py = {
            icon = '',
            color = '#3572A5',
            name = 'Python',
          },
        },
      }
    end,
  },
  {
    'akinsho/bufferline.nvim',
    version = '*',
    opts = {
      options = {
        mode = 'buffers',
        numbers = 'none',
        show_buffer_icons = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        show_tab_indicators = false,
        color_icons = false,
        diagnostics = 'none',
        separator_style = 'thin',
        always_show_bufferline = true,
        enforce_regular_tabs = true,
        sort_by = 'insert_at_end', -- supported value
        persist_buffer_sort = true, -- remember your order across sessions
        hover = { enabled = false },
        name_formatter = function(buf)
          local path = buf.path or ''
          if path == '' then return buf.name end

          -- Split the path into parts
          local parts = {}
          for part in string.gmatch(path, '[^/]+') do
            table.insert(parts, part)
          end

          local count = #parts
          local filename = parts[count] -- always show full filename
          local parent1 = parts[count - 1]

          if count >= 2 then
            local p1 = parent1 or ''
            if #p1 > 10 then p1 = p1:sub(1, 10) .. '…' end
            return p1 .. '/' .. filename
          else
            return filename
          end
        end,
      },
      highlights = {
        buffer_selected = { bold = false, italic = false },
        buffer_visible = { bold = false, italic = false },
      },
    },
    keys = {
      { 'gt', '<Cmd>BufferLineCycleNext<CR>', desc = 'Next buffer (bufferline order)' },
      { 'gT', '<Cmd>BufferLineCyclePrev<CR>', desc = 'Prev buffer (bufferline order)' },
      -- optional: reorder with Alt+h/l (keeps “shown order” under your control)
      { '<A-h>', '<Cmd>BufferLineMovePrev<CR>', desc = 'Move buffer left' },
      { '<A-l>', '<Cmd>BufferLineMoveNext<CR>', desc = 'Move buffer right' },
    },
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup {
        options = {
          theme = 'auto',
          icons_enabled = true,
          section_separators = '',
          component_separators = '',
          globalstatus = true,
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = { 'diagnostics', 'filename' },
          -- lualine_c = { 'diff', 'filename' },
          lualine_x = {
            {
              function() return '  ' end,
              padding = { left = 1, right = 1 },
            },
          },
          lualine_y = {
            { 'progress' },
            { 'selectioncount' },
          },
          lualine_z = {
            'location',
          },
        },
      }
    end,
  },
  { -- Automatically highlights other instances of the word under your cursor.
    'RRethy/vim-illuminate',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      delay = 200,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { 'lsp' },
      },
    },
    config = function(_, opts)
      require('illuminate').configure(opts)
      local function map(key, dir, buffer)
        vim.keymap.set(
          'n',
          key,
          function() require('illuminate')['goto_' .. dir .. '_reference'](false) end,
          { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. ' Reference', buffer = buffer }
        )
      end

      map(']]', 'next')
      map('[[', 'prev')

      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map(']]', 'next', buffer)
          map('[[', 'prev', buffer)
        end,
      })
    end,
    keys = {
      { ']]', desc = 'Next Reference' },
      { '[[', desc = 'Prev Reference' },
    },
  },
  -- { 'norcalli/nvim-colorizer.lua', config = true },
  {
    'folke/noice.nvim',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    config = function()
      require('noice').setup {
        presets = {
          long_message_to_split = false,
          inc_rename = false,
        },
        cmdline = {
          enabled = true,
          view = 'cmdline',
          format = {
            search_down = {
              view = 'cmdline',
            },
            search_up = {
              view = 'cmdline',
            },
          },
        },
        messages = {
          enabled = true,
        },
        routes = {
          {
            filter = {
              event = 'msg_show',
              kind = 'echo',
            },
            opts = { skip = true },
          },
          {
            filter = {
              event = 'msg_show',
              kind = 'quickfix',
            },
            opts = { skip = true },
          },
        },
        views = {
          cmdline_popup = {
            border = {
              style = 'rounded',
              padding = { 0, 0 }, -- vertical, horizontal
            },
            position = {
              row = -3,
              col = '50%',
            },
            size = {
              width = '40%',
              height = 'auto',
            },
            win_options = {
              -- winhighlight = 'NormalFloat:NormalFloat,FloatBorder:FloatBorder',
              -- cursorline = false,
              winhighlight = '', -- empty disables custom highlights
            },
            filter_options = {
              -- prevents `!` from triggering filter mode
              pattern = '^:%s*[!?]',
              icon = '$',
              lang = 'bash',
            },
          },
        },
      }
    end,
  },
  {
    'kdheepak/lazygit.nvim',
    lazy = true,
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    keys = {
      { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    },
  },
  {
    'tpope/vim-fugitive',
    cmd = { 'Git', 'Gdiffsplit' },
  },
  {
    'sindrets/diffview.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
  },
  {
    -- Live Markdown preview
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && yarn install',
    init = function() vim.g.mkdp_filetypes = { 'markdown' } end,
    ft = { 'markdown' },
  },
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    cmd = { 'ToggleTerm', 'TermExec' },
    keys = {
      { '<C-\\>', '<cmd>ToggleTerm<CR>', desc = 'Toggle Terminal' },
    },
    config = function()
      require('toggleterm').setup {
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = 'float',
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = 'curved',
          winblend = 0,
          highlights = {
            border = 'Normal',
            background = 'Normal',
          },
        },
      }
    end,
  },
  {
    'goolord/alpha-nvim',
    event = 'VimEnter',
    lazy = false,
    priority = 100,
    config = function()
      local alpha = require 'alpha'
      local dashboard = require 'alpha.themes.dashboard'

      local arts = {}

      arts.figureb = {
        '                                           ',
        '                                           ',
        '                                           ',
        '                   @@@@                    ',
        '                @@@@@@@@@@@                ',
        '               @@@@@@@@%#%@@               ',
        '              @@@@@@@@@@@@@@@              ',
        '              @@@@@@@@@%%@@@@@             ',
        '              @%=-=@@=-=-#@@@@             ',
        '              @##@+##=#@+=@@@@             ',
        '              @@+=---:---#@@@@             ',
        '              @%+---:--==*@@@@@            ',
        '              @@+++==+==-=@%*@@            ',
        '             @@%-:-==-:...+@@@@@           ',
        '            @@%:..::.......*@@@@@@         ',
        '           @@@-............-@@@@@@@        ',
        '         @@@@#:..........:::-%@@@@@@       ',
        '         @@@#:...............-%@@@@@@      ',
        '        @@@%:.................+@@@@@@@     ',
        '       @@@@-..................=@@@@@@@     ',
        '      @@@@#...................-%@@@@@@@    ',
        '      @@@@*...................-@@@@@@@@    ',
        '      +=-+#+.................:=@@@@@%#     ',
        '  =====----*@*..............--+@@@@%=--    ',
        ' +=---------+@@#:..........:-===++=----    ',
        ' +=----------+@@+..........-+=------------ ',
        ' +=-----------=-.........:#@*=------------ ',
        ' +=------------+*=-::-=#@@@@*=--------===  ',
        ' ++++====-----=*%@@@@@@@@@@@*=----==++     ',
        '      *##******#%          %#*+++**        ',
        '            %%%              %%%%          ',
        '                                           ',
      }

      -- dashboard.section.header.val = require('arts').random()
      dashboard.section.header.val = arts.figureb
      dashboard.section.buttons.val = {}

      local function footer()
        local quotes = {
          '"[TODO]" – [TODO]"',
        }
        return quotes
      end
      dashboard.section.footer.val = footer()
      dashboard.section.header.opts = {
        position = 'center',
        hl = 'AlphaHeader',
      }
      dashboard.section.footer.opts = {
        position = 'center',
        hl = 'AlphaFooter',
      }

      dashboard.config.layout = {
        { type = 'padding', val = 2 },
        dashboard.section.header,
        { type = 'padding', val = 2 },
        dashboard.section.buttons,
        { type = 'padding', val = 2 },
        dashboard.section.footer,
      }

      alpha.setup(dashboard.config)
    end,
  },
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      plugins = {
        marks = false,
      },
      win = {
        border = 'rounded',
        padding = { 0, 0, 0, 0 },
      },
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch' },
      },
    },
  },

  { -- Fuzzy Finder
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
        defaults = {
          file_ignore_patterns = {
            'node_modules',
            'venv',
            '.venv',
            '__pycache__',
            '.git/',
            '.idea/',
            '.vscode/',
            'build/',
            'dist/',
            'target/',
            'coverage/',
            '%.class',
            '%.o',
            '%.so',
            '%.pyc',
            '%.log',
            '%.tmp',
            '%.DS_Store',
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set(
        'n',
        '<leader>sF',
        function()
          builtin.find_files {
            hidden = true,
          }
        end,
        { desc = '[S]earch hidden [F]iles' }
      )
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set(
        'n',
        '<leader>sg',
        function()
          require('telescope.builtin').live_grep {
            cwd = vim.fn.getcwd(),
            prompt_title = 'Live Grep in working directory',
          }
        end,
        { desc = '[S]earch by [G]rep (cwd)' }
      )
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>so', function()
        local bufs = vim.tbl_filter(
          function(buf) return vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'modifiable') end,
          vim.api.nvim_list_bufs()
        )

        local files = {}
        for _, buf in ipairs(bufs) do
          local name = vim.api.nvim_buf_get_name(buf)
          if name ~= '' then table.insert(files, name) end
        end

        require('telescope.builtin').live_grep {
          search_dirs = files,
        }
      end, { desc = '[S]earch [O]pen Buffers' })

      vim.keymap.set(
        'n',
        '<leader>sc',
        function()
          builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
            winblend = 10,
            previewer = false,
          })
        end,
        { desc = '[S]earch in [C]urrent buffer' }
      )

      vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
    end,
  },
  -- LSP Plugins
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = vim.env.VIMRUNTIME },
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end
        end,
      })

      -- Diagnostic Config
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      local servers = {
        html = {},
        cssls = {},
        emmet_ls = {},
        jsonls = {},
        pyright = {
          settings = {
            python = {
              venvPath = '.',
              venv = '.venv',
              analysis = {
                diagnosticMode = 'workspace',
                autoSearchPaths = true,
                -- Add the current working directory as an extra path
                extraPaths = { vim.fn.getcwd() },
              },
            },
          },
        },
        bashls = {},
        phpactor = {},
        clangd = {},
        gopls = {},
        rust_analyzer = {},
        dockerls = {},
        sqls = {},
        texlab = {},
        marksman = {},
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = 'LuaJIT',
              },
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                callSnippet = 'Replace',
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        -- Formatters
        'stylua', -- Lua
        'prettierd', -- JS/TS/HTML/CSS
        'jinja-lsp', -- Jinja templates
        'shfmt', -- Shell scripts
        'black', -- Python
        'isort', -- Python imports
        'clang-format', -- C/C++
        -- Linters
        'flake8', -- Python
        'eslint_d', -- JS/TS
        -- Additional tools
        'bash-language-server',
        'clangd',
        'css-lsp',
        'dockerfile-language-server',
        'emmet-ls',
        'eslint-lsp',
        'gopls',
        'html-lsp',
        'json-lsp',
        'lua-language-server',
        'marksman',
        'prettier',
        'prisma-language-server',
        'pyright',
        'ruff',
        'rust-analyzer',
        'sqls',
        'typescript-language-server',
      })

      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
      }
      require('mason-lspconfig').setup {
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format { async = true, lsp_format = 'fallback' } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = function(_, opts)
      opts.notify_on_error = false
      local prettier = M_FROM_UTILS
      opts.format_on_save = function(bufnr)
        -- Disable format on save for all filetypes except Lua
        if vim.bo[bufnr].filetype == 'lua' then
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        else
          return nil
        end
      end
      opts.formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'black', 'isort' },
        javascript = { 'prettierd', 'prettier' },
        typescript = { 'prettierd', 'prettier' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        zsh = { 'shfmt' },
        c = { 'clang-format' },
        java = { 'google-java-format' },
        rust = { 'rustfmt' },
        go = { 'gofmt' },
        cpp = { 'clang-format' },
        html = { 'prettierd', 'prettier' },
        markdown = { 'prettierd', 'prettier' },
      }
      opts.formatters = opts.formatters or {}
      opts.formatters.shfmt = {}
      opts.formatters.prettier = {
        condition = function(_, ctx) return prettier.has_parser(ctx) and (vim.g.prettier_needs_config ~= true or prettier.has_config(ctx)) end,
      }
    end,
  },
  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = 'make install_jsregexp',
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            config = function() require('luasnip.loaders.from_vscode').lazy_load() end,
          },
        },
        config = function()
          local ls = require 'luasnip'
          require('luasnip.loaders.from_snipmate').lazy_load {
            -- paths = { '~/snippets/' },
          }
          vim.keymap.set({ 'i', 's' }, '<Tab>', function()
            if ls.expand_or_jumpable() then
              ls.expand_or_jump()
            else
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
            end
          end, { silent = true })
          vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
            if ls.jumpable(-1) then
              ls.jump(-1)
            else
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<S-Tab>', true, false, true), 'n', false)
            end
          end, { silent = true })
        end,
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    opts = {
      keymap = {
        preset = 'default',
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = {
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },
  {
    'hedyhli/outline.nvim',
    config = function() require('outline').setup() end,
    keys = {
      { '<leader>k', '<cmd>Outline<CR>', desc = 'Toggle Outline' },
    },
  },
  {
    'folke/trouble.nvim',
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = 'Trouble',
    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Buffer Diagnostics (Trouble)',
      },
      {
        '<leader>cs',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = 'Symbols (Trouble)',
      },
      {
        '<leader>cl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = 'LSP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xL',
        '<cmd>Trouble loclist toggle<cr>',
        desc = 'Location List (Trouble)',
      },
      {
        '<leader>xQ',
        '<cmd>Trouble qflist toggle<cr>',
        desc = 'Quickfix List (Trouble)',
      },
    },
  },
  -- Gruvbox Theme
  -- {
  --   'morhetz/gruvbox',
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.o.background = 'dark'
  --   end,
  -- },

  -- Popular Themes
  { 'ellisonleao/gruvbox.nvim' }, -- Gruvbox
  { 'navarasu/onedark.nvim' }, -- Onedark
  { 'catppuccin/nvim', name = 'catppuccin' }, -- Catppuccin
  { 'shaunsingh/nord.nvim' }, -- Nord
  { 'folke/tokyonight.nvim' }, -- TokyoNight
  { 'talha-akram/noctis.nvim' },
  -- { 'projekt0n/github-nvim-theme' }, -- GitHub Theme
  -- { 'EdenEast/nightfox.nvim' }, -- Carbonfox (Nightfox Variant)
  -- { 'drewtempelmeyer/palenight.vim' }, -- Palenight
  -- { 'jaredgorski/spacecamp' }, -- Spacecamp
  { 'doums/darcula' }, -- Darcula
  -- { 'mhartington/oceanic-next' }, -- Oceanic Next
  -- { 'sjl/badwolf' }, -- Badwolf
  -- { 'NLKNguyen/papercolor-theme' }, -- PaperColor
  -- { 'dracula/vim' }, -- Dracula
  -- { 'nanotech/jellybeans.vim' }, -- Jellybeans
  -- { 'NTBBloodbath/doom-one.nvim' }, -- Doom One
  -- { 'lifepillar/vim-solarized8' }, -- Solarized8
  -- { 'sainnhe/edge' }, -- Edge
  -- { 'cocopon/iceberg.vim' }, -- Iceberg
  -- { 'loctvl842/monokai-pro.nvim' }, -- Monokai Pro

  -- Fancy & Unique Themes
  { 'marko-cerovac/material.nvim' }, -- Material
  { 'EdenEast/nightfox.nvim' }, -- Nightfox
  { 'Mofiqul/dracula.nvim' }, -- Dracula
  { 'sainnhe/everforest' }, -- Everforest
  { 'rose-pine/neovim', name = 'rose-pine' }, -- Rose Pine

  -- Dark & Futuristic Themes
  -- { 'ishan9299/nvim-solarized-lua' }, -- Solarized
  -- { 'rebelot/kanagawa.nvim' }, -- Kanagawa
  { 'Shatur/neovim-ayu' }, -- Ayu
  { 'glepnir/zephyr-nvim' }, -- Zephyr

  -- Minimalist Themes
  { 'sainnhe/gruvbox-material' }, -- PaperColor/Material Gruvbox
  { 'sainnhe/edge' }, -- Edge
  { 'tanvirtin/monokai.nvim' }, -- Monokai
  {
    'folke/tokyonight.nvim',
    -- enabled = false,
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
      }
    end,
  },
  -- Solarized Theme
  -- {
  --   'lifepillar/vim-solarized8',
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.o.termguicolors = true
  --     vim.o.background = 'light'
  --   end,
  -- },
  -- catppuccin
  {
    'catppuccin/nvim',
    lazy = true,
    name = 'catppuccin',
    opts = {
      lsp_styles = {
        underlines = {
          errors = { 'undercurl' },
          hints = { 'undercurl' },
          warnings = { 'undercurl' },
          information = { 'undercurl' },
        },
      },
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        fzf = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        mini = true,
        navic = { enabled = true, custom_bg = 'lualine' },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        snacks = true,
        telescope = true,
        treesitter_context = true,
        which_key = true,
      },
    },
    specs = {
      {
        'akinsho/bufferline.nvim',
        optional = true,
        opts = function(_, opts)
          if (vim.g.colors_name or ''):find 'catppuccin' then opts.highlights = require('catppuccin.special.bufferline').get_theme() end
        end,
      },
    },
  },
  -- Highlights and lists all of the TODO, HACK, BUG, etc comment
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup {
        mappings = {
          add = 'S', -- Add surround
        },
        custom_surroundings = {
          b = { input = '**', output = '**' }, -- bold
          i = { input = '*', output = '*' }, -- italic
          c = { input = '`', output = '`' }, -- code
        },
      }
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },
  { -- Find gallery at https://tinted-theming.github.io/tinted-gallery/
    -- Nice themes that I like: base24-flexoki-dark , outrun-dark , sleepy-hollow , penumbra-dark-contrast-plus , base24-ayu-dark
    'tinted-theming/tinted-vim',
    lazy = false,
    enabled = false,
    priority = 1000,
  },

  -- Restoring previously open buffers
  -- {
  --   'rmagatti/auto-session',
  --   lazy = false,
  --   opts = {
  --     log_level = 'error',
  --     auto_session_enable_last_session = true,
  --     auto_session_root_dir = vim.fn.stdpath 'data' .. '/sessions',
  --     auto_session_enabled = true,
  --     suppressed_dirs = { '~/', '~/Downloads', '/' },
  --   },
  -- },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    branch = 'main',
    lazy = false,
    config = function()
      local ts = require 'nvim-treesitter'
      local parsers = {
        'bash',
        'bash',
        'c',
        'diff',
        'regex',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'json',
        'python',
        'javascript',
        'typescript',
        'java',
        'go',
        'rust',
        'cpp',
        'css',
        'tsx',
        'yaml',
        'toml',
        'dockerfile',
        'make',
        'perl',
        'sql',
        'gitignore',
      }

      for _, parser in ipairs(parsers) do
        ts.install(parser)
      end

      -- dynamically collect all filetypes each parser handles
      -- this correctly maps tsx -> typescriptreact etc.
      local patterns = {}
      for _, parser in ipairs(parsers) do
        for _, ft in ipairs(vim.treesitter.language.get_filetypes(parser)) do
          table.insert(patterns, ft)
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = patterns,
        callback = function()
          vim.treesitter.start()
          vim.wo.foldmethod = 'expr'
          vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.wo.foldlevel = 99
        end,
      })
    end,
  },
  -- { -- Add indentation guides even on blank lines
  --   'lukas-reineke/indent-blankline.nvim',
  --   -- Enable `lukas-reineke/indent-blankline.nvim`
  --   -- See `:help ibl`
  --   main = 'ibl',
  --   opts = {},
  -- },
  { -- Small independent plugins
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = false },
      dim = { enabled = false },
      explorer = {
        enabled = false,
      },
      indent = { enabled = false },
      input = { enabled = true },
      picker = { enabled = true },
      notifier = { enabled = false },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
      statuscolumn = { enabled = true },
      words = { enabled = false },
      terminal = {
        bo = {
          filetype = 'snacks_terminal',
        },
        wo = {},
        stack = true, -- when enabled, multiple split windows with the same position will be stacked together (useful for terminals)
        keys = {
          q = 'hide',
          gf = function(self)
            local f = vim.fn.findfile(vim.fn.expand '<cfile>', '**')
            if f == '' then
              Snacks.notify.warn 'No file under cursor'
            else
              self:hide()
              vim.schedule(function() vim.cmd('e ' .. f) end)
            end
          end,
          term_normal = {
            '<esc>',
            function(self)
              self.esc_timer = self.esc_timer or (vim.uv or vim.loop).new_timer()
              if self.esc_timer:is_active() then
                self.esc_timer:stop()
                vim.cmd 'stopinsert'
              else
                self.esc_timer:start(200, 0, function() end)
                return '<esc>'
              end
            end,
            mode = 't',
            expr = true,
            desc = 'Double escape to normal mode',
          },
        },
      },
    },
    keys = {
      -- Explorer
      {
        '<leader>E',
        function() Snacks.explorer() end,
        desc = 'File Explorer',
      },
      {
        '<leader>er',
        function() Snacks.explorer.reveal() end,
        desc = 'File Explorer',
      },
      -- Terminal
      {
        '<leader>t',
        function() Snacks.terminal() end,
        desc = 'Toggle Terminal',
      },

      -- git
      {
        '<leader>gb',
        function() Snacks.picker.git_branches() end,
        desc = 'Git Branches',
      },
      {
        '<leader>gl',
        function() Snacks.picker.git_log() end,
        desc = 'Git Log',
      },
      {
        '<leader>gL',
        function() Snacks.picker.git_log_line() end,
        desc = 'Git Log Line',
      },
      {
        '<leader>gs',
        function() Snacks.picker.git_status() end,
        desc = 'Git Status',
      },
      {
        '<leader>gD',
        function() Snacks.picker.git_status() end,
        desc = 'Git Diff',
      },
      -- gh
      {
        '<leader>gi',
        function() Snacks.picker.gh_issue() end,
        desc = 'GitHub Issues (open)',
      },
      {
        '<leader>gI',
        function() Snacks.picker.gh_issue { state = 'all' } end,
        desc = 'GitHub Issues (all)',
      },
      {
        '<leader>gp',
        function() Snacks.picker.gh_pr() end,
        desc = 'GitHub Pull Requests (open)',
      },
      {
        '<leader>gP',
        function() Snacks.picker.gh_pr { state = 'all' } end,
        desc = 'GitHub Pull Requests (all)',
      },
      -- search
      {
        '<leader>sr',
        function() Snacks.picker.search_history() end,
        desc = 'Search History',
      },
      -- Other
      { '<leader>n', '<cmd>Noice pick<cr>', desc = 'Notification History' },
      {
        '<leader>cR',
        function() Snacks.rename.rename_file() end,
        desc = 'Rename File',
      },
    },
  },
  { -- File Explorer
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- for icons
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
      { '~', ':Neotree toggle<CR>', desc = 'NeoTree toggle', silent = true },
    },
    opts = {
      close_if_last_window = true, -- auto-close Neo-tree if it's the last window
      popup_border_style = 'rounded', -- rounded floating border
      enable_git_status = true, -- show git info
      enable_diagnostics = false, -- disable lint/diagnostics
      sources = { 'filesystem', 'buffers', 'git_status' },
      open_files_do_not_replace_types = { 'terminal', 'Trouble', 'trouble', 'qf', 'Outline' },
      default_component_configs = {
        container = {
          enable_character_fade = true,
        },
        indent = {
          padding = 1,
          indent_size = 2,
          with_markers = true,
          highlight = 'NeoTreeIndentMarker',
          with_expanders = true,
          expander_collapsed = '',
          expander_expanded = '',
          expander_highlight = 'NeoTreeExpander',
        },
        icon = {
          folder_closed = '',
          folder_open = '',
          folder_empty = '',
          default = '',
        },
        name = { trailing_slash = false, use_git_status_colors = true },
        git_status = {
          -- symbols = { added = '✚', modified = '', removed = '✖' },
          symbols = {
            unstaged = '󰄱',
            staged = '󰱒',
            untracked = '',
            ignored = '',
            renamed = '󰁕',
            deleted = '󰍛',
          },
        },
      },

      filesystem = {
        use_libuv_file_watcher = true,
        follow_current_file = { enabled = true }, -- always highlight current file
        hijack_netrw_behavior = 'disabled', -- keep netrw disabled
        filtered_items = { visible = false },
        window = {
          width = 35,
          mappings = {
            ['<CR>'] = 'open',
            ['l'] = 'open',
            ['h'] = 'close_node',
            ['H'] = 'none',
            ['L'] = 'none',
            ['V'] = 'open_vsplit',
            ['S'] = 'open_split',
            ['w'] = 'open',
            ['\\'] = 'close_window',
            ['~'] = 'close_window',
            ['<A-h>'] = 'toggle_hidden',
            ['oc'] = { 'order_by_created', nowait = false },
            ['od'] = { 'order_by_diagnostics', nowait = false },
            ['og'] = { 'order_by_git_status', nowait = false },
            ['om'] = { 'order_by_modified', nowait = false },
            ['on'] = { 'order_by_name', nowait = false },
            ['os'] = { 'order_by_size', nowait = false },
            ['ot'] = { 'order_by_type', nowait = false },
            ['Y'] = {
              function(state)
                local node = state.tree:get_node()
                local path = node:get_id()
                vim.fn.setreg('+', path, 'c')
                vim.notify 'Path copied to clipboard'
              end,
              desc = 'Copy Path to Clipboard',
            },
            ['O'] = {
              function(state) require('lazy.util').open(state.tree:get_node().path, { system = true }) end,
              desc = 'Open with System Application',
            },
            ['P'] = { 'toggle_preview', config = { use_float = false } },
          },
        },
      },
      buffers = { follow_current_file = true },
      git_status = { follow_current_file = true },
      global = true,
    },
  },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.cmd.colorscheme 'ayu'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
