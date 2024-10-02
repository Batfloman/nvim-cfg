require 'first.remap'

-- Remove default keymaps
vim.keymap.del('n', 'grn')
vim.keymap.del('n', 'grr')
vim.keymap.del('n', 'gra')
vim.keymap.del('x', 'gra')

-- Sets indentation
vim.opt.tabstop = 3 -- Number of visual spaces per TAB
vim.opt.shiftwidth = 3 -- Number of spaces to use for each step of (auto)indent
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.smartindent = true -- Enable smart indentation
vim.opt.autoindent = true -- Copy indent from current line when starting a new line

-- Load Plugins
require 'first.config.lazy'
