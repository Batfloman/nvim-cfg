return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    -- manage created terminals & order to open/toggle terminals
    local terms = {}
    local shell_names = {
      bash = true,
      zsh = true,
      fish = true,
      sh = true,
      dash = true,
      nu = true,
    }

    local function read_first_line(path)
      local ok, lines = pcall(vim.fn.readfile, path)
      if not ok or lines == nil or lines[1] == nil then
        return nil
      end
      return lines[1]
    end

    local function read_cmdline(path)
      local ok, lines = pcall(vim.fn.readfile, path, 'b')
      if not ok or lines == nil or lines[1] == nil then
        return nil
      end
      return lines[1]
    end

    local function get_child_pids(pid)
      local line = read_first_line('/proc/' .. pid .. '/task/' .. pid .. '/children')
      if line == nil or line == '' then
        return {}
      end

      local pids = {}
      for child_pid in line:gmatch '%d+' do
        table.insert(pids, tonumber(child_pid))
      end
      return pids
    end

    local function process_label(pid)
      local comm = read_first_line('/proc/' .. pid .. '/comm')
      if comm == nil or comm == '' then
        return nil
      end

      if comm:match '^python%d*%.?%d*$' then
        local cmdline = read_cmdline('/proc/' .. pid .. '/cmdline')
        if cmdline ~= nil then
          local venv = cmdline:match '/([^/]+)/bin/python%d*%.?%d*'
          if venv ~= nil and venv ~= '' and venv ~= 'usr' then
            return 'py:' .. venv
          end
        end
      end

      return comm
    end

    local function get_foreground_process_label(shell_pid)
      if vim.uv.fs_stat '/proc' == nil then
        return nil
      end

      local function walk(pid)
        local children = get_child_pids(pid)
        for i = #children, 1, -1 do
          local label = walk(children[i])
          if label ~= nil then
            return label
          end
        end

        local label = process_label(pid)
        if label ~= nil and not shell_names[label] then
          return label
        end

        return nil
      end

      return walk(shell_pid)
    end

    local function path_for_label(path)
      if path == nil or path == '' then
        return '[unknown]'
      end

      local nvim_cwd = vim.fn.getcwd()
      if nvim_cwd ~= nil and nvim_cwd ~= '' then
        if path == nvim_cwd then
          return './'
        end

        local cwd_prefix = nvim_cwd .. '/'
        if path:sub(1, #cwd_prefix) == cwd_prefix then
          return './' .. path:sub(#cwd_prefix + 1)
        end
      end

      return vim.fn.fnamemodify(path, ':~')
    end

    local function get_term_cwd(term)
      if term == nil or term.job_id == nil then
        return nil
      end

      local pid = vim.fn.jobpid(term.job_id)
      if pid == nil or pid <= 0 then
        return nil
      end

      return vim.uv.fs_readlink('/proc/' .. pid .. '/cwd')
    end

    local function refresh_term_display_name(term)
      if term == nil then
        return
      end

      local cwd = get_term_cwd(term) or term.dir or vim.uv.cwd()
      local cwd_label = path_for_label(cwd)
      local project = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
      if project == nil or project == '' then
        project = '.'
      end

      local proc_label = nil
      if term.job_id ~= nil then
        local shell_pid = vim.fn.jobpid(term.job_id)
        if shell_pid ~= nil and shell_pid > 0 then
          proc_label = get_foreground_process_label(shell_pid)
        end
      end

      local suffix = proc_label ~= nil and (' [' .. proc_label .. ']') or ''
      term.display_name = string.format('[Terminal %d] %s %s%s', term.id, project, cwd_label, suffix)
    end

    local function refresh_all_term_display_names()
      for _, term in ipairs(terms) do
        refresh_term_display_name(term)
      end
    end

    local function get_current_file_dir()
      local path = vim.api.nvim_buf_get_name(0)
      if path == nil or path == '' then
        return vim.fn.getcwd()
      end

      return vim.fn.fnamemodify(path, ':p:h')
    end

    local function get_project_root()
      local bufnr = vim.api.nvim_get_current_buf()
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        local root_dir = client.config and client.config.root_dir
        if root_dir ~= nil and root_dir ~= '' then
          return root_dir
        end
      end

      local path = vim.api.nvim_buf_get_name(bufnr)
      local start_path = (path ~= nil and path ~= '') and vim.fs.dirname(path) or vim.fn.getcwd()
      local git_root = vim.fs.root(start_path, '.git')
      if git_root ~= nil and git_root ~= '' then
        return git_root
      end

      return vim.fn.getcwd()
    end

    -- default settings
    require('toggleterm').setup {
      dir = vim.fn.expand '%:p:h',
      direction = 'float',
      on_open = function(t) -- move term to the back of 'terms' table
        refresh_term_display_name(t)

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
        refresh_term_display_name(t)
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

    vim.keymap.set('n', '<leader>To', function() -- Toggle term
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

    vim.keymap.set('n', '<leader>Tc', function() -- Create new Terminal in current dir
      local Terminal = require('toggleterm.terminal').Terminal
      local dir = get_current_file_dir()

      local term = Terminal:new {
        dir = dir,
      }

      term:toggle()
    end, { desc = '[T]erminal [c]reate (in file dir)' })

    vim.keymap.set('n', '<leader>TC', function() -- Create new Terminal in project root
      local Terminal = require('toggleterm.terminal').Terminal

      local term = Terminal:new {
        dir = get_project_root(),
      }

      term:toggle()
    end, { desc = '[T]erminal create (project [r]oot)' })

    vim.keymap.set('n', '<leader>Tl', function() -- List Terminals
      refresh_all_term_display_names()
      vim.cmd 'TermSelect'
    end, { desc = '[T]erminal [l]ist' })

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
        local term_mod = require 'toggleterm.terminal'
        local id = term_mod.get_focused_id()
        if id ~= nil then
          refresh_term_display_name(term_mod.get(id))
        end
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

    -- change terminal orientation with configurable modes
    local function set_term_direction_map(lhs, direction, modes, extra)
      vim.keymap.set(modes, lhs, function()
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
    set_term_direction_map('<A-h>', 'horizontal', { 'n', 't' })
    set_term_direction_map('<A-f>', 'float', { 'n', 't' })
    set_term_direction_map('<A-v>', 'vertical', { 'n', 't' }, function(term)
      term:resize(50)
    end)
    set_term_direction_map('<A-t>', 'tab', { 'n', 't' })

    set_term_direction_map('<leader>Th', 'horizontal', { 'n' })
    set_term_direction_map('<leader>Tf', 'float', { 'n' })
    set_term_direction_map('<leader>Tv', 'vertical', { 'n' }, function(term)
      term:resize(50)
    end)
    set_term_direction_map('<leader>Tt', 'tab', { 'n' })
  end,
}
