-- Load all Lua plugin files from the config path
local plugins = {}

-- Function to load all plugins from a directory
local function load_plugins_from_dir(dir, module_prefix)
  for file, type in vim.fs.dir(dir) do
    local path = dir .. '/' .. file

    if type == 'directory' then
      -- Recursive call for subdirectories, update module_prefix
      local prefix = (module_prefix or 'plugins.') .. file .. '.'
      load_plugins_from_dir(path, prefix)
    elseif type == 'file' and file:match '%.lua$' then
      -- Construct the module name
      local module_name = (module_prefix or 'plugins.') .. file:sub(1, -5) -- Remove .lua
      local success, plugin = pcall(require, module_name) -- Load the plugin
      if success then
        table.insert(plugins, plugin) -- Add the plugin to the list
      else
        print('Error loading plugin', module_name, '\n', plugin)
      end
    end
  end
end

-- Load all plugins from the plugins folder
local plugin_folder_path = vim.fn.stdpath 'config' .. '/lua/plugins'
load_plugins_from_dir(plugin_folder_path)

return plugins
