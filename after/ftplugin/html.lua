local port = 5500
local url = 'http://127.0.0.1:' .. port
local last_target = url
vim.g.html_live_server_job = vim.g.html_live_server_job or nil
vim.g.html_live_server_root = vim.g.html_live_server_root or nil

local uname = (vim.uv or vim.loop).os_uname()
local is_wsl = uname.release:lower():find('microsoft', 1, true) ~= nil

local function available(cmd)
  return vim.fn.executable(cmd) == 1
end

local function candidates(target)
  local list = {}

  if is_wsl then
    if available('wslview') then
      list[#list + 1] = { name = 'wslview', cmd = { 'wslview', target } }
    end
    if available('powershell.exe') then
      list[#list + 1] = { name = 'powershell.exe', cmd = { 'powershell.exe', '-NoProfile', '-Command', 'Start-Process "' .. target .. '"' } }
    end
    if available('cmd.exe') then
      list[#list + 1] = { name = 'cmd.exe', cmd = { 'cmd.exe', '/C', 'start', '', target } }
    end
  end

  if vim.fn.has('mac') == 1 and available('open') then
    list[#list + 1] = { name = 'open', cmd = { 'open', target } }
  end
  if vim.fn.has('win32') == 1 and available('rundll32') then
    list[#list + 1] = { name = 'rundll32', cmd = { 'rundll32', 'url.dll,FileProtocolHandler', target } }
  end
  if available('xdg-open') then
    list[#list + 1] = { name = 'xdg-open', cmd = { 'xdg-open', target } }
  end

  return list
end

local function open_url(target)
  local openers = candidates(target)
  if #openers == 0 then
    vim.notify('No URL opener found. Install one of: wslview, xdg-open, open, powershell.exe', vim.log.levels.ERROR)
    return
  end

  local failures = {}
  for _, opener in ipairs(openers) do
    vim.notify('Opening ' .. target .. ' via ' .. opener.name, vim.log.levels.INFO)
    if vim.system then
      local result = vim.system(opener.cmd, { text = true }):wait()
      if result.code == 0 then
        vim.notify('Opened ' .. target .. ' via ' .. opener.name, vim.log.levels.INFO)
        return
      end
      local err = (result.stderr or ''):gsub('%s+$', '')
      if err == '' then
        err = 'no stderr output'
      end
      failures[#failures + 1] = opener.name .. ' (exit ' .. result.code .. ': ' .. err .. ')'
    else
      local job = vim.fn.jobstart(opener.cmd, { detach = false })
      if job > 0 then
        vim.notify('Launched opener via ' .. opener.name, vim.log.levels.INFO)
        return
      end
      failures[#failures + 1] = opener.name .. ' (jobstart error ' .. job .. ')'
    end
  end

  vim.notify('Could not open URL. Tried: ' .. table.concat(failures, '; '), vim.log.levels.ERROR)
end

local function stop_live_server()
  if vim.g.html_live_server_job and vim.fn.jobwait({ vim.g.html_live_server_job }, 0)[1] == -1 then
    vim.fn.jobstop(vim.g.html_live_server_job)
    vim.g.html_live_server_job = nil
    vim.g.html_live_server_root = nil
    vim.notify('live-server stopped', vim.log.levels.INFO)
    return
  end

  vim.g.html_live_server_job = nil
  vim.g.html_live_server_root = nil
  vim.notify('No running live-server job', vim.log.levels.WARN)
end

vim.keymap.set('n', '<leader>ll', function()
  if vim.fn.executable('npx') ~= 1 then
    vim.notify('npx is not available in PATH', vim.log.levels.ERROR)
    return
  end

  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file path for current buffer', vim.log.levels.WARN)
    return
  end

  local file_dir = vim.fn.fnamemodify(file, ':h')
  local file_name = vim.fn.fnamemodify(file, ':t')
  last_target = url .. '/' .. file_name

  if vim.g.html_live_server_job and vim.fn.jobwait({ vim.g.html_live_server_job }, 0)[1] == -1 then
    vim.fn.jobstop(vim.g.html_live_server_job)
    vim.g.html_live_server_job = nil
    vim.notify('Restarting live-server for: ' .. file_dir, vim.log.levels.INFO)
  end

  local job = vim.fn.jobstart({
    'npx',
    '--yes',
    'live-server',
    '--no-browser',
    '--port=' .. port,
  }, {
    detach = false,
    cwd = file_dir,
    on_exit = function(_, code)
      vim.schedule(function()
        vim.g.html_live_server_job = nil
        vim.g.html_live_server_root = nil
        if code ~= 0 then
          vim.notify('live-server exited with code ' .. code .. ' (check if port ' .. port .. ' is already in use)', vim.log.levels.ERROR)
        end
      end)
    end,
  })
  if job <= 0 then
    vim.notify('Failed to start live-server', vim.log.levels.ERROR)
    return
  end

  vim.g.html_live_server_job = job
  vim.g.html_live_server_root = file_dir
  vim.notify('live-server started for ' .. file .. ' on ' .. last_target .. ' (use <leader>lo to open)', vim.log.levels.INFO)
end, { buffer = true, desc = 'Live serve current HTML file' })

vim.keymap.set('n', '<leader>lo', function()
  open_url(last_target)
end, { buffer = true, desc = 'Open live site in browser' })

vim.keymap.set('n', '<leader>lq', function()
  stop_live_server()
end, { buffer = true, desc = 'Stop live server' })

vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.api.nvim_create_augroup('html-live-server-cleanup', { clear = true }),
  callback = function()
    stop_live_server()
  end,
})
