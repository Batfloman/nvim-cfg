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
            elseif path:match '%.root$' then
              local root = require 'custom_commands.cern_root'
              local actions = {
                {
                  label = 'ROOT browser',
                  run = function()
                    root.browse(path)
                  end,
                },
                {
                  label = 'Classic TBrowser',
                  run = function()
                    root.browse(path, { classic = true })
                  end,
                },
                {
                  label = 'ROOT console',
                  run = function()
                    root.console(path)
                  end,
                },
                {
                  label = 'Neovim listing',
                  run = function()
                    root.list(path)
                  end,
                },
              }

              vim.ui.select(actions, {
                prompt = 'Open ROOT file with:',
                format_item = function(item)
                  return item.label
                end,
              }, function(choice)
                if choice ~= nil then
                  choice.run()
                end
              end)
            else
              require('neo-tree.sources.filesystem.commands').open(state)
            end
          end,
        },
      },
    },
  },
}
