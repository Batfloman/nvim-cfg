--[[
--
-- This file is not required for your own configuration,
-- but helps people determine if their system is setup correctly.
--
--]]

local check_version = function()
  local verstr = tostring(vim.version())
  if not vim.version.ge then
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
    return
  end

  if vim.version.ge(vim.version(), '0.10-dev') then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
  end
end

local check_external_reqs = function()
  -- Basic utils: `git`, `make`, `unzip`
  for _, exe in ipairs { 'git', 'make', 'unzip', 'rg' } do
    local is_executable = vim.fn.executable(exe) == 1
    if is_executable then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end

  return true
end

local check_live_server_workflow = function()
  vim.health.start 'Live Server Workflow'

  local uv = vim.uv or vim.loop
  local uname = uv.os_uname()
  local is_wsl = uname.release:lower():find('microsoft', 1, true) ~= nil

  if vim.fn.executable('npx') == 1 then
    vim.health.ok("Found executable: 'npx'")
  else
    vim.health.warn("Missing executable: 'npx' (required for `npx live-server`)")
  end

  if vim.fn.executable('live-server') == 1 then
    vim.health.ok("Found executable: 'live-server'")
  else
    vim.health.info("`live-server` not global, that's fine if you use `npx --yes live-server`")
  end

  if is_wsl then
    vim.health.info 'WSL detected'
    if vim.fn.executable('wslview') == 1 then
      vim.health.ok("Found executable: 'wslview'")
    else
      vim.health.warn("Missing executable: 'wslview' (install package `wslu` for better URL opening in WSL)")
    end
    if vim.fn.executable('powershell.exe') == 1 then
      vim.health.ok("Found executable: 'powershell.exe'")
    else
      vim.health.warn("Missing executable: 'powershell.exe' (WSL Windows URL opener fallback)")
    end
  end

  if vim.fn.executable('xdg-open') == 1 or vim.fn.executable('open') == 1 or vim.fn.executable('wslview') == 1 then
    vim.health.ok 'Found at least one URL opener command'
  else
    vim.health.warn("No URL opener found (`xdg-open`, `open`, or `wslview`)")
  end
end

return {
  check = function()
    vim.health.start 'nvim config'

    vim.health.info [[NOTE: Not every warning is a 'must-fix' in `:checkhealth`

  Fix only warnings for plugins and languages you intend to use.
    Mason will give warnings for languages that are not installed.
    You do not need to install, unless you want to use those languages!]]

    local uv = vim.uv or vim.loop
    vim.health.info('System Information: ' .. vim.inspect(uv.os_uname()))

    check_version()
    check_external_reqs()
    check_live_server_workflow()
  end,
}
