local M = {}

local function map(bufnr, keys, func, desc, mode)
  vim.keymap.set(mode or 'n', keys, func, {
    buffer = bufnr,
    desc = 'LSP: ' .. desc,
  })
end

local function setup_keymaps(bufnr)
  local telescope = require 'telescope.builtin'

  map(bufnr, 'gd', telescope.lsp_definitions, '[G]oto [D]efinition')
  map(bufnr, 'gr', telescope.lsp_references, '[G]oto [R]eferences')
  map(bufnr, 'gI', telescope.lsp_implementations, '[G]oto [I]mplementation')
  map(bufnr, '<leader>D', telescope.lsp_type_definitions, 'Type [D]efinition')
  map(bufnr, '<leader>ds', telescope.lsp_document_symbols, '[D]ocument [S]ymbols')
  map(bufnr, '<leader>ws', telescope.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
  map(bufnr, '<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  map(bufnr, '<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
  map(bufnr, 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
end

local function setup_document_highlight(client, bufnr)
  if not client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
    return
  end

  local group = vim.api.nvim_create_augroup('lsp-document-highlight', { clear = false })
  vim.api.nvim_clear_autocmds { group = group, buffer = bufnr }

  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    buffer = bufnr,
    group = group,
    callback = vim.lsp.buf.document_highlight,
  })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    buffer = bufnr,
    group = group,
    callback = vim.lsp.buf.clear_references,
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    buffer = bufnr,
    group = group,
    callback = function(event)
      vim.lsp.buf.clear_references()
      vim.api.nvim_clear_autocmds { group = group, buffer = event.buf }
    end,
  })
end

local function setup_inlay_hints(client, bufnr)
  if not client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
    return
  end

  vim.b[bufnr].inlay_hints_enabled = true
  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

  local group = vim.api.nvim_create_augroup('lsp-inlay-hints', { clear = false })
  vim.api.nvim_clear_autocmds { group = group, buffer = bufnr }

  vim.api.nvim_create_autocmd('InsertEnter', {
    buffer = bufnr,
    group = group,
    callback = function(event)
      if vim.b[event.buf].inlay_hints_enabled then
        vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
      end
    end,
  })

  vim.api.nvim_create_autocmd('InsertLeave', {
    buffer = bufnr,
    group = group,
    callback = function(event)
      if vim.b[event.buf].inlay_hints_enabled then
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
      end
    end,
  })

  map(bufnr, '<leader>th', function()
    local enabled = not vim.b[bufnr].inlay_hints_enabled
    vim.b[bufnr].inlay_hints_enabled = enabled
    vim.lsp.inlay_hint.enable(enabled and vim.api.nvim_get_mode().mode ~= 'i', { bufnr = bufnr })
  end, '[T]oggle Inlay [H]ints')
end

function M.on_attach(event)
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if not client then
    return
  end

  setup_keymaps(event.buf)
  setup_document_highlight(client, event.buf)
  setup_inlay_hints(client, event.buf)
end

return M
