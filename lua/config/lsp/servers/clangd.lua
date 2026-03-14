return {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
  root_dir = require('lspconfig.util').root_pattern('.clangd', '.clang-tidy', '.clang-format', 'compile_commands.json', 'compile_flags.txt', '.git'),
  capabilities = {
    offsetEncoding = { 'utf-16' },
  },
  settings = {
    clangd = {
      fallbackFlags = { '-std=c++17' },
    },
  },
}
