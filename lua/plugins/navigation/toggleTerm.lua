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

    vim.keymap.set('t', '<C-Space>h', function()
      local modu = require 'toggleterm.terminal'
      local id = modu.get_focused_id() or modu.get_last_focused()
      local term = require('toggleterm.terminal').get(id)
      if term ~= nil and term.direction ~= 'horizontal' then
        term:close()
        term.direction = 'horizontal'
        term:open()
      end
    end, { desc = '[T]erminal move horizontal' })

    vim.keymap.set('t', '<C-Space>f', function()
      local modu = require 'toggleterm.terminal'
      local id = modu.get_focused_id() or modu.get_last_focused()
      local term = require('toggleterm.terminal').get(id)
      if term ~= nil and term.direction ~= 'float' then
        term:close()
        term.direction = 'float'
        term:open()
      end
    end, { desc = '[T]erminal move horizontal' })

    vim.keymap.set('t', '<C-Space>v', function()
      local modu = require 'toggleterm.terminal'
      local id = modu.get_focused_id() or modu.get_last_focused()
      local term = require('toggleterm.terminal').get(id)
      if term ~= nil and term.direction ~= 'vertical' then
        term:close()
        term.direction = 'vertical'
        term:open()
      end
    end, { desc = '[T]erminal move horizontal' })
  end,
}
