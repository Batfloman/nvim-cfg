local M = {}

local tools = {
  'clang-format',
  'markdownlint-cli2',
  'prettierd',
  'stylua',
}

local function setup_inlay_hint_highlight()
  local function apply()
    local comment = vim.api.nvim_get_hl(0, { name = 'Comment' })
    vim.api.nvim_set_hl(0, 'LspInlayHint', {
      default = false,
      fg = comment.fg,
      italic = true,
    })
  end

  apply()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('lsp-inlay-hint-highlight', { clear = true }),
    callback = apply,
  })
end

local function setup_attach_autocmd()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
    callback = require('config.lsp.attach').on_attach,
  })
end

local function make_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
  capabilities.workspace = capabilities.workspace or {}
  capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = true }
  return capabilities
end

local function setup_mason(servers)
  require('mason').setup()

  require('mason-lspconfig').setup {
    ensure_installed = vim.tbl_keys(servers),
    automatic_enable = false,
  }

  require('mason-tool-installer').setup {
    ensure_installed = tools,
  }
end

local function enable_servers(servers, capabilities)
  for name, config in pairs(servers) do
    config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

function M.setup()
  local servers = require 'config.lsp.servers'

  setup_inlay_hint_highlight()
  setup_attach_autocmd()
  setup_mason(servers)
  enable_servers(servers, make_capabilities())
end

return M
