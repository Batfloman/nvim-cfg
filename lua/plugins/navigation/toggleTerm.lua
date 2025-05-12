return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      dir = vim.fn.expand '%:p:h',
      direction = 'float',
      on_create = function(t)
        local dir = vim.fn.expand '%:p:h'
        dir = string.match(dir, '~/(.+)//')
        t.display_name = string.format('[Terminal %d] - %s', t.id, dir)
      end,
    }

    vim.keymap.set({ 'n', 't' }, '<C-T>', function()
      local count = vim.v.count > 0 and vim.v.count or nil
      require('toggleterm').toggle(count)
    end, { desc = 'Toggle Terminal (with optional count)' })

    vim.keymap.set({ 'n', 't' }, '<leader>Tc', function()
      local Terminal = require('toggleterm.terminal').Terminal
      local dir = vim.fn.expand '%:p:h'

      local term = Terminal:new {
        dir = dir,
        direction = 'float',
      }
      term.display_name = string.format('[Terminal %d] - %s', term.id, dir)

      term:toggle()
    end, { desc = '[T]erminal [c]reate (in file dir)' })

    vim.keymap.set('n', '<leader>Tl', '<cmd>TermSelect<CR>', { desc = '[T]erminal [l]ist' })
  end,
}
