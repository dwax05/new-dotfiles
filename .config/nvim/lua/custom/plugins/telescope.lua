local actions = require 'telescope.actions'

require('telescope').setup {
  defaults = {
    mappings = {
      i = { -- Insert mode
        ['<C-j>'] = actions.move_selection_next,
        ['<C-k>'] = actions.move_selection_previous,
      },
      n = { -- Normal mode
        ['<C-j>'] = actions.move_selection_next,
        ['<C-k>'] = actions.move_selection_previous,
      },
    },
  },
}

return {}
