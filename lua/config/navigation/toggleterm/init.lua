local M = {}

local process = require 'config.navigation.toggleterm.process'

function M.setup()
  -- Manage created terminals and their most-recently-opened order.
  local terms = {}

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
        proc_label = process.foreground_label(shell_pid)
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

  local term_output_pending = {}
  local term_modes = {}
  local set_term_winbar

  local function get_focused_term()
    local term_mod = require 'toggleterm.terminal'
    local id = term_mod.get_focused_id()
    if id == nil then
      return nil
    end

    return term_mod.get(id)
  end

  local function term_is_at_bottom(term)
    if term == nil or term.window == nil or not vim.api.nvim_win_is_valid(term.window) then
      return false
    end

    return vim.api.nvim_win_call(term.window, function()
      local view = vim.fn.winsaveview()
      local win_height = vim.api.nvim_win_get_height(0)
      local line_count = vim.api.nvim_buf_line_count(term.bufnr)
      return view.topline + win_height - 1 >= line_count
    end)
  end

  local function clear_term_output_if_at_bottom(term)
    if term ~= nil and term_is_at_bottom(term) then
      term_output_pending[term.id] = nil
    end
  end

  local function mark_term_output(term)
    vim.schedule(function()
      if term == nil or term.id == nil then
        return
      end

      if not term_is_at_bottom(term) then
        term_output_pending[term.id] = true
        if set_term_winbar ~= nil then
          set_term_winbar(term_modes[term.id] or 'NORMAL', term)
        end
      end
    end)
  end

  require('toggleterm').setup {
    dir = vim.fn.expand '%:p:h',
    direction = 'float',
    auto_scroll = false,
    on_stdout = mark_term_output,
    on_stderr = mark_term_output,
    on_open = function(opened_term)
      refresh_term_display_name(opened_term)

      for i, term in ipairs(terms) do
        if term.id == opened_term.id then
          table.remove(terms, i)
          table.insert(terms, term)
          break
        end
      end
    end,
    on_create = function(term)
      refresh_term_display_name(term)
      table.insert(terms, term)
    end,
    on_exit = function(exited_term)
      term_output_pending[exited_term.id] = nil
      term_modes[exited_term.id] = nil

      for i, term in ipairs(terms) do
        if term.id == exited_term.id then
          table.remove(terms, i)
          break
        end
      end
    end,
  }

  vim.keymap.set('n', '<leader>To', function()
    -- TODO: add vim.v.count support
    for i = #terms, 1, -1 do
      local term = terms[i]
      if term.direction == 'float' then
        term:toggle()
        return
      end
    end

    require('toggleterm.terminal').Terminal:new():toggle()
  end, { desc = 'Toggle floating terminal (with optional count)' })

  vim.keymap.set('n', '<leader>Tc', function()
    local Terminal = require('toggleterm.terminal').Terminal
    local term = Terminal:new {
      dir = get_current_file_dir(),
    }

    term:toggle()
  end, { desc = '[T]erminal [c]reate (in file dir)' })

  vim.keymap.set('n', '<leader>TC', function()
    local Terminal = require('toggleterm.terminal').Terminal
    local term = Terminal:new {
      dir = get_project_root(),
    }

    term:toggle()
  end, { desc = '[T]erminal create (project [r]oot)' })

  vim.keymap.set('n', '<leader>Tl', function()
    refresh_all_term_display_names()
    vim.cmd 'TermSelect'
  end, { desc = '[T]erminal [l]ist' })

  local original_timeout = vim.o.timeoutlen
  set_term_winbar = function(mode, term)
    term = term or get_focused_term()
    if term ~= nil then
      term_modes[term.id] = mode
    end

    local hint = mode == 'INSERT' and '<Esc><Esc> -> NORMAL' or 'i -> INSERT'
    local output_marker = term ~= nil and term_output_pending[term.id] and '  [new output]' or ''
    local winbar = string.format(' Terminal [%s]%s  %s ', mode, output_marker, hint)

    if term ~= nil and term.window ~= nil and vim.api.nvim_win_is_valid(term.window) then
      vim.api.nvim_win_call(term.window, function()
        vim.wo.winbar = winbar
      end)
      return
    end

    vim.wo.winbar = winbar
  end

  vim.api.nvim_create_autocmd('TermEnter', {
    callback = function()
      vim.o.timeoutlen = 1500
      local term = get_focused_term()
      if term ~= nil then
        clear_term_output_if_at_bottom(term)
        refresh_term_display_name(term)
      end
      set_term_winbar('INSERT', term)
    end,
  })

  vim.api.nvim_create_autocmd('TermLeave', {
    callback = function()
      vim.o.timeoutlen = original_timeout
      set_term_winbar 'NORMAL'
    end,
  })

  vim.api.nvim_create_autocmd({ 'WinScrolled', 'CursorMoved' }, {
    callback = function()
      local term = get_focused_term()
      clear_term_output_if_at_bottom(term)
      if term ~= nil then
        set_term_winbar(term_modes[term.id] or 'NORMAL', term)
      end
    end,
  })

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
end

return M
