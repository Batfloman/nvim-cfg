return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      direction = 'float',
    }

    vim.keymap.set({ 'n', 't' }, '<C-T>', function()
      require('toggleterm').toggle()
    end, { desc = 'Toggle Terminal' })

    vim.keymap.set({ 'n', 't' }, '<leader>Tc', function()
      local Terminal = require('toggleterm.terminal').Terminal
      local dir = vim.fn.expand '%:p:h'

      local term = Terminal:new {
        display_name = dir,
        dir = dir,
        direction = 'float',
      }
      term:toggle()
      -- vim.cmd('ToggleTermSetName ' .. dir)
    end, { desc = '[T]erminal [c]reate (in file dir)' })

    vim.keymap.set('n', '<leader>Tl', '<cmd>TermSelect<CR>', { desc = '[T]erminal [l]ist' })
  end,
}
