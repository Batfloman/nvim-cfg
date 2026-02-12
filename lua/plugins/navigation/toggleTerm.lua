return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    -- manage created terminals & order to open/toggle terminals
    local terms = {}

    -- default settings
    require('toggleterm').setup {
      dir = vim.fn.expand '%:p:h',
      direction = 'float',
      on_open = function(t) -- move term to the back of 'terms' table
        for i, term in ipairs(terms) do
          if term.id == t.id then
            -- Element ans Ende verschieben
            table.remove(terms, i)
            table.insert(terms, term)
            break
          end
        end
      end,
      on_create = function(t) -- init
        local dir = vim.fn.expand '%:p:h'
        dir = string.match(dir, '~/(.+)//')
        t.display_name = string.format('[Terminal %d] - %s', t.id, dir)
        table.insert(terms, t)
      end,
      on_exit = function(t) -- auto clean
        for i, term in ipairs(terms) do
          if term.id == t.id then
            table.remove(terms, i)
            break
          end
        end
      end,
    }

    -- ==================================================
    -- Keymaps

    vim.keymap.set({ 'n', 't' }, '<leader>To', function() -- Toggle term
      -- TODO: add vim.v.count support

      -- toggle the last opened 'float' terminal
      for i = #terms, 1, -1 do
        local term = terms[i]
        if term.direction == 'float' then
          term:toggle()
          return
        end
      end

      -- create float term if there are none
      require('toggleterm.terminal').Terminal:new():toggle()
    end, { desc = 'Toggle floating terminal (with optional count)' })

    vim.keymap.set({ 'n', 't' }, '<leader>Tc', function() -- Create new Terminal in current dir
      local Terminal = require('toggleterm.terminal').Terminal
      local dir = vim.fn.expand '%:p:h' -- use current filepath

      local term = Terminal:new {
        dir = dir,
      }

      term:toggle()
    end, { desc = '[T]erminal [c]reate (in file dir)' })

    vim.keymap.set('n', '<leader>Tl', '<cmd>TermSelect<CR>', { desc = '[T]erminal [l]ist' }) -- List Terminals

    -- ==================================================
    -- In Terminal Keybinds / UX

    local original_timeout = vim.o.timeoutlen
    local function set_term_winbar(mode)
      local hint = mode == 'INSERT' and '<Esc><Esc> -> NORMAL' or 'i -> INSERT'
      vim.wo.winbar = string.format(' Terminal [%s]  %s ', mode, hint)
    end

    vim.api.nvim_create_autocmd('TermEnter', {
      callback = function()
        vim.o.timeoutlen = 1500
        set_term_winbar 'INSERT'
      end,
    })

    vim.api.nvim_create_autocmd('TermLeave', {
      callback = function()
        vim.o.timeoutlen = original_timeout
        set_term_winbar 'NORMAL'
      end,
    })

    -- fast way to leave terminal-insert mode
    vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { desc = 'Terminal normal mode' })

    local function get_active_term()
      local term_mod = require 'toggleterm.terminal'
      local id = term_mod.get_focused_id()
      if id ~= nil then
        local focused = term_mod.get(id)
        if focused ~= nil then
          return focused
        end
      end

      for i = #terms, 1, -1 do
        if terms[i] ~= nil then
          return terms[i]
        end
      end
    end

    -- change terminal orientation from normal or terminal mode
    local function set_term_direction_map(lhs, direction, extra)
      vim.keymap.set({ 'n', 't' }, lhs, function()
        local term = get_active_term()
        local Terminal = require('toggleterm.terminal').Terminal

        if term == nil then
          term = Terminal:new { direction = direction, dir = vim.fn.expand '%:p:h' }
          if extra then
            extra(term)
          end
          term:toggle()
          return
        end

        if term.direction ~= direction then
          term:close()
          term.direction = direction
          if extra then
            extra(term)
          end
          term:open()
        end
      end, { desc = '[T]erminal direction ' .. direction })
    end

    -- Quick mappings (single keystroke chord) + leader fallbacks
    set_term_direction_map('<A-h>', 'horizontal')
    set_term_direction_map('<A-f>', 'float')
    set_term_direction_map('<A-v>', 'vertical', function(term)
      term:resize(50)
    end)
    set_term_direction_map('<A-t>', 'tab')

    set_term_direction_map('<leader>Th', 'horizontal')
    set_term_direction_map('<leader>Tf', 'float')
    set_term_direction_map('<leader>Tv', 'vertical', function(term)
      term:resize(50)
    end)
    set_term_direction_map('<leader>Tt', 'tab')
  end,
}
