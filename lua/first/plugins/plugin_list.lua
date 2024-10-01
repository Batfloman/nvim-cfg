-- Get the config path using vim.fn.stdpath
local config_path = vim.fn.stdpath 'config' .. '/lua/first/plugins'

-- Load all Lua plugin files from the config path
local plugin_files = vim.fn.globpath(config_path, '*.lua', false, true)
local plugins = {}

for _, file in ipairs(plugin_files) do
  local module_name = vim.fn.fnamemodify(file, ':t:r')

  -- Ensure we do not require the loader file itself
  if module_name ~= 'plugin_list' then
    table.insert(plugins, require('first.plugins.' .. module_name))
  end
end

return plugins
