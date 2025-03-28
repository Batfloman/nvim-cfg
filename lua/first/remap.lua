-- Remove default keymaps
local keys_to_delete = {
  { mode = 'n', key = 'grn' },
  { mode = 'n', key = 'grr' },
  { mode = 'n', key = 'gra' },
  { mode = 'x', key = 'gra' },
}

for _, map in ipairs(keys_to_delete) do
  if vim.fn.maparg(map.key, map.mode) ~= '' then -- Check if the mapping exists
    vim.api.nvim_del_keymap(map.mode, map.key)
  end
end

vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)
