-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['gx'] = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            if path:match '%.pdf$' then
              vim.fn.jobstart({ 'zathura', path }, { detach = true })
            else
              require('neo-tree.sources.filesystem.commands').open(state)
            end
          end,
        },
      },
    },
  },
}
