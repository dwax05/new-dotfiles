M = {
  'monaqa/dial.nvim',
  config = function()
    local augend = require 'dial.augend'
    require('dial.config').augends:register_group {
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.date.alias['%Y/%m/%d'],
        augend.date.alias['%Y-%m-%d'],
        augend.date.alias['%m/%d'],
        augend.date.alias['%H:%M'],
        augend.constant.new {
          elements = { 'true', 'false' },
          word = true,
          cyclic = true,
        },
        augend.constant.new {
          elements = { '&&', '||' },
          word = false,
          cyclic = true,
        },
        augend.hexcolor.new {
          case = 'prefer_lower', -- or "lower", "prefer_upper", "prefer_lower", see below
        },
        augend.constant.alias.alpha,
        augend.constant.alias.Alpha,
      },
    }

    -- change augends in NORMAL mode
    vim.keymap.set('n', '<C-a>', require('dial.map').inc_normal 'default', { noremap = true })
    vim.keymap.set('n', '<C-x>', require('dial.map').dec_normal 'default', { noremap = true })
  end,
}

return M
