require 'remap'

-- Sets indentation
vim.opt.tabstop = 5 -- Number of visual spaces per TAB
vim.opt.shiftwidth = 5 -- Number of spaces to use for each step of (auto)indent
vim.opt.expandtab = false -- Use spaces instead of tabs
vim.opt.smartindent = true -- Enable smart indentation
vim.opt.autoindent = true -- Copy indent from current line when starting a new line

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable line numbers
vim.opt.number = true -- Set absolute line numbers
vim.opt.relativenumber = true -- Set relative line numbers
-- Align absolute line numbers to the left and relative line numbers to the right
vim.opt.numberwidth = 5 -- Set the width of the number column
vim.opt.signcolumn = 'yes' -- Show sign column to avoid shifting text

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'
-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 12
-- Show which line your cursor is on
vim.opt.cursorline = true

-- Load Plugins
require 'config.lazy'
