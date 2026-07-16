local M = {}

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

function M.foreground_label(shell_pid)
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

return M
