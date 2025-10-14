return {
  {
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
      }
      -- vim.cmd.colorscheme 'tokyonight-night'
    end,
  },
  {
    'sainnhe/everforest',
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      -- vim.cmd.colorscheme 'rose-pine'
    end,
  },
  {
    'AlphaTechnolog/pywal.nvim',
    config = function()
      -- vim.cmd.colorscheme 'pywal'
    end,
  },
  {
    'ellisonleao/gruvbox.nvim',
    config = function()
      vim.cmd.colorscheme 'gruvbox'
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
