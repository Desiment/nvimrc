-- Local, project-oriented Neovim config for Python development.
-- Requested stack: built-in LSP, VS Code snippets, which-key, lualine, nvim-tree, git signs.

vim.g.mapleader = ' '
vim.g.maplocalleader = ','

local home = vim.fn.expand('~')
local nvim_venv = home .. '/.local/share/nvim/python-venv'
local nvim_bin = home .. '/.local/bin'
local nvim_bin_groups = table.concat({
  nvim_bin,
  nvim_bin .. '/dev',
  nvim_bin .. '/documents',
  nvim_bin .. '/teaching',
  nvim_bin .. '/desktop',
  nvim_bin .. '/network',
}, ':')
local cargo_bin = (vim.env.XDG_DATA_HOME or (home .. '/.local/share')) .. '/cargo/bin'
local tool_bin = nvim_venv .. '/bin'

vim.g.python3_host_prog = tool_bin .. '/python'
vim.env.PATH = tool_bin .. ':' .. nvim_bin_groups .. ':' .. cargo_bin .. ':' .. vim.env.PATH

-- Core editor defaults
vim.opt.number = true
vim.opt.relativenumber = true
-- Enable mouse support in all modes so clicks can reposition the cursor.
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
vim.opt.background = 'light'
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.undofile = true
vim.opt.clipboard = 'unnamedplus'

-- Keep Python files aligned with vega project style.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function()
    vim.opt_local.colorcolumn = '92'
    vim.opt_local.textwidth = 92
  end,
})

local function apply_latex_highlights()
  local palette = {
    text = '#657b83',
    comment = '#93a1a1',
    command = '#268bd2',
    structure = '#6c71c4',
    math = '#2aa198',
    error = '#dc322f',
  }

  local groups = {
    -- VimTeX syntax groups
    texStatement = palette.command,
    texCmd = palette.command,
    texCmdEnv = palette.command,
    texCmdPart = palette.structure,
    texCmdPackage = palette.command,
    texCmdRef = palette.math,
    texCmdCite = palette.math,
    texEnvArgName = palette.structure,
    texArg = palette.text,
    texOpt = palette.text,
    texPartArgTitle = palette.structure,
    texMathZone = palette.math,
    texMathDelim = palette.math,
    texMathSymbol = palette.math,
    texMathOper = palette.math,
    texRefArg = palette.math,
    texCiteArg = palette.math,
    texFileArg = palette.math,
    texComment = palette.comment,

    -- Treesitter captures scoped to LaTeX/BibTeX.
    ['@function.latex'] = palette.command,
    ['@function.builtin.latex'] = palette.command,
    ['@keyword.latex'] = palette.command,
    ['@keyword.directive.latex'] = palette.command,
    ['@module.latex'] = palette.command,
    ['@markup.heading.latex'] = palette.structure,
    ['@markup.strong.latex'] = palette.structure,
    ['@markup.italic.latex'] = palette.structure,
    ['@markup.math.latex'] = palette.math,
    ['@string.latex'] = palette.text,
    ['@variable.latex'] = palette.text,
    ['@punctuation.bracket.latex'] = palette.text,
    ['@punctuation.delimiter.latex'] = palette.text,
    ['@comment.latex'] = palette.comment,
    ['@property.bibtex'] = palette.command,
    ['@string.bibtex'] = palette.text,
    ['@variable.bibtex'] = palette.text,
    ['@punctuation.bracket.bibtex'] = palette.text,
    ['@punctuation.delimiter.bibtex'] = palette.text,
  }

  for group, fg in pairs(groups) do
    vim.api.nvim_set_hl(0, group, { fg = fg })
  end

  vim.api.nvim_set_hl(0, 'texComment', { fg = palette.comment, italic = true })
  vim.api.nvim_set_hl(0, '@comment.latex', { fg = palette.comment, italic = true })
  vim.api.nvim_set_hl(0, 'texError', { fg = palette.error })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = apply_latex_highlights,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'tex', 'bib' },
  callback = apply_latex_highlights,
})

-- Bootstrap lazy.nvim locally.
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Disable netrw before nvim-tree loads.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('lazy').setup({
  -- Solarized Light colorscheme
  {
    'lifepillar/vim-solarized8',
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.background = 'light'
      vim.cmd.colorscheme('solarized8')
    end,
  },

  -- LaTeX editing, compilation, and PDF integration
  {
    'lervag/vimtex',
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_compiler_method = 'latexmk'
      vim.g.vimtex_compiler_latexmk = {
        callback = 1,
        continuous = 1,
        executable = 'latexmk',
        options = {
          '-pdf',
          '-interaction=nonstopmode',
          '-synctex=1',
        },
      }
    end,
  },

  -- Keybinding discovery
  {
    'folke/which-key.nvim',
    lazy = false,
    opts = {},
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)
      wk.add({
        { '<leader>b', group = 'buffers' },
        { '<leader>d', group = 'debug' },
        { '<leader>e', desc = 'Toggle file tree' },
        { '<leader>f', group = 'files/format' },
        { '<leader>g', group = 'git' },
        { '<leader>l', group = 'lsp' },
        { '<leader>s', group = 'snippets/search' },
        { '<leader>t', group = 'tests/tree' },
      })
    end,
  },

  -- Lua statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        theme = 'auto',
        globalstatus = true,
        component_separators = '|',
        section_separators = '',
      },
      sections = {
        lualine_c = { { 'filename', path = 1 } },
      },
    },
  },

  -- File tree
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '<leader>e', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle file tree' },
      { '<leader>fr', '<cmd>NvimTreeFindFile<cr>', desc = 'Reveal current file in tree' },
    },
    opts = {
      sort = { sorter = 'case_sensitive' },
      view = { width = 34 },
      git = { enable = true, ignore = false },
      renderer = {
        group_empty = true,
        highlight_git = true,
        icons = { show = { git = true, folder = true, file = true, folder_arrow = true } },
      },
      filters = { dotfiles = false },
    },
  },

  -- Git signs and hunks
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map('n', ']h', gs.next_hunk, 'Next git hunk')
        map('n', '[h', gs.prev_hunk, 'Previous git hunk')
        map('n', '<leader>gp', gs.preview_hunk, 'Preview hunk')
        map('n', '<leader>gs', gs.stage_hunk, 'Stage hunk')
        map('n', '<leader>gr', gs.reset_hunk, 'Reset hunk')
        map('n', '<leader>gb', gs.blame_line, 'Blame line')
      end,
    },
  },

  -- Treesitter syntax/highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local parsers = { 'python', 'lua', 'vim', 'vimdoc', 'toml', 'json', 'yaml', 'bash', 'markdown', 'markdown_inline', 'latex', 'bibtex' }
      local filetypes = { 'python', 'lua', 'vim', 'vimdoc', 'toml', 'json', 'yaml', 'sh', 'bash', 'markdown', 'tex', 'bib' }

      require('nvim-treesitter').setup({
        install_dir = vim.fn.stdpath('data') .. '/site',
      })

      vim.treesitter.language.register('bash', 'sh')
      vim.treesitter.language.register('latex', 'tex')
      vim.treesitter.language.register('bibtex', 'bib')
      require('nvim-treesitter').install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        pattern = filetypes,
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- VS Code-like snippets
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
    build = 'make install_jsregexp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load()
      require('luasnip').config.setup({
        history = true,
        updateevents = 'TextChanged,TextChangedI',
      })
    end,
  },

  -- Completion
  {
    'hrsh7th/nvim-cmp',
    lazy = false,
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'saadparwaiz1/cmp_luasnip',
      'L3MON4D3/LuaSnip',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        }, {
          { name = 'buffer' },
        }),
      })
    end,
  },

  -- Formatting via project-aligned ruff settings from pyproject.toml
  {
    'stevearc/conform.nvim',
    lazy = false,
    keys = {
      {
        '<leader>lf',
        function()
          require('conform').format({ async = true, lsp_format = 'fallback' })
        end,
        desc = 'Format buffer',
      },
    },
    opts = {
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 3000, lsp_format = 'fallback' }
      end,
      formatters_by_ft = {
        python = { 'ruff_fix', 'ruff_organize_imports', 'ruff_format' },
        tex = { 'latexindent' },
      },
      formatters = {
        ruff_fix = { command = tool_bin .. '/ruff' },
        ruff_organize_imports = { command = tool_bin .. '/ruff' },
        ruff_format = { command = tool_bin .. '/ruff' },
        latexindent = { command = 'latexindent' },
      },
    },
  },

  -- Debugging with debugpy
  {
    'mfussenegger/nvim-dap',
    lazy = false,
    dependencies = { 'mfussenegger/nvim-dap-python' },
    keys = {
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Toggle breakpoint' },
      { '<leader>dc', function() require('dap').continue() end, desc = 'Continue' },
      { '<leader>di', function() require('dap').step_into() end, desc = 'Step into' },
      { '<leader>do', function() require('dap').step_over() end, desc = 'Step over' },
      { '<leader>dO', function() require('dap').step_out() end, desc = 'Step out' },
      { '<leader>dr', function() require('dap').repl.open() end, desc = 'Open DAP REPL' },
      { '<leader>dt', function() require('dap-python').test_method() end, desc = 'Debug Python test method' },
    },
    config = function()
      require('dap-python').setup(tool_bin .. '/python')
    end,
  },
}, {
  checker = { enabled = false, notify = false },
  change_detection = { enabled = false, notify = false },
  install = { colorscheme = { 'solarized8', 'habamax' } },
})

-- Built-in LSP configuration. No nvim-lspconfig required.
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
if ok_cmp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

vim.diagnostic.config({
  virtual_text = { spacing = 2, source = 'if_many' },
  severity_sort = true,
  float = { border = 'rounded', source = true },
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local bufnr = event.buf
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end
    map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
    map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
    map('n', 'gr', vim.lsp.buf.references, 'References')
    map('n', 'K', vim.lsp.buf.hover, 'Hover documentation')
    map('n', '<leader>la', vim.lsp.buf.code_action, 'Code action')
    map('n', '<leader>lr', vim.lsp.buf.rename, 'Rename symbol')
    map('n', '<leader>ld', vim.diagnostic.open_float, 'Line diagnostics')
    map('n', '[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
    map('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')
  end,
})

local basedpyright = tool_bin .. '/basedpyright-langserver'
local ruff = tool_bin .. '/ruff'

vim.lsp.config('basedpyright', {
  cmd = { basedpyright, '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'uv.lock', '.git' },
  capabilities = capabilities,
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
        useLibraryCodeForTypes = true,
        typeCheckingMode = 'standard',
      },
    },
  },
})

vim.lsp.config('ruff', {
  cmd = { ruff, 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  capabilities = capabilities,
  init_options = {
    settings = {
      logLevel = 'warn',
    },
  },
})

vim.lsp.config('texlab', {
  cmd = { 'texlab' },
  filetypes = { 'tex', 'plaintex', 'bib' },
  root_markers = { '.latexmkrc', 'latexmkrc', 'main.tex', '.git' },
  capabilities = capabilities,
})

vim.lsp.enable({ 'basedpyright', 'ruff', 'texlab' })

-- General keymaps
vim.keymap.set('n', '<leader>w', '<cmd>write<cr>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit window' })
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>tn', '<cmd>tabnew<cr>', { desc = 'New tab' })
vim.keymap.set('n', '<leader>th', '<cmd>split<cr>', { desc = 'Horizontal split' })
vim.keymap.set('n', '<leader>tv', '<cmd>vsplit<cr>', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>/', function()
  vim.cmd('vimgrep /' .. vim.fn.input('Search: ') .. '/gj **/*')
  vim.cmd('copen')
end, { desc = 'Project search via vimgrep' })

-- Python test convenience using project pytest config.
vim.keymap.set('n', '<leader>tt', function()
  vim.cmd('write')
  vim.cmd('terminal ' .. tool_bin .. '/pytest')
end, { desc = 'Run pytest' })

vim.keymap.set('n', '<leader>tf', function()
  vim.cmd('write')
  vim.cmd('terminal ' .. tool_bin .. '/pytest ' .. vim.fn.expand('%'))
end, { desc = 'Run pytest for current file' })
