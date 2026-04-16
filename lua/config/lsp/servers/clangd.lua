local util = require 'lspconfig.util'

return {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
  root_dir = function(bufnr, on_dir)
    local fname = type(bufnr) == 'number' and vim.api.nvim_buf_get_name(bufnr) or bufnr
    if fname == nil or fname == '' then
      return
    end

    local root = util.root_pattern('.clangd', '.clang-tidy', '.clang-format', 'compile_commands.json', 'compile_flags.txt', '.git')(fname)
      or vim.fs.dirname(fname)
    on_dir(root)
  end,
  capabilities = {
    offsetEncoding = { 'utf-16' },
  },
  settings = {
    clangd = {
      fallbackFlags = { '-std=c++17' },
    },
  },
}
