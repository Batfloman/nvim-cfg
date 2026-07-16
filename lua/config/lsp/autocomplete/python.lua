local M = {}

local show_all_members = false

local function cursor_before_line()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return line:sub(1, col)
end

local function is_member_completion(context)
  local before = context and context.cursor_before_line or cursor_before_line()
  return before:match '%.%s*[%w_]*$' ~= nil
end

local function is_dunder(label)
  return label:match '^__.*__$' ~= nil
end

local function entry_label(entry)
  return entry.completion_item.label or entry.word or ''
end

local function completion_text(entry)
  local item = entry.completion_item
  if type(item.textEdit) == 'table' then
    return item.textEdit.newText or entry_label(entry)
  end

  return item.insertText or entry_label(entry)
end

local function is_named_parameter(entry)
  return entry_label(entry):match '=%s*$' ~= nil or completion_text(entry):match '=%s*$' ~= nil
end

local function parameter_name(entry)
  return completion_text(entry):match '^%s*([%a_][%w_]*)%s*=' or entry_label(entry):match '^%s*([%a_][%w_]*)%s*='
end

local function is_named_argument_value(context)
  local before = context and context.cursor_before_line or cursor_before_line()
  return before:match '[%a_][%w_]*%s*=%s*$' ~= nil
end

local function compare_named_parameters(entry1, entry2)
  local parameter1 = is_named_parameter(entry1)
  local parameter2 = is_named_parameter(entry2)

  if parameter1 ~= parameter2 then
    return parameter1
  end

  return nil
end

local function visibility_category(entry)
  local label = entry_label(entry)

  if is_dunder(label) then
    return 2
  end

  if label:sub(1, 1) == '_' then
    return 1
  end

  return 0
end

local function compare_visibility(entry1, entry2)
  if not is_member_completion() then
    return nil
  end

  local category1 = visibility_category(entry1)
  local category2 = visibility_category(entry2)
  if category1 ~= category2 then
    return category1 < category2
  end

  return nil
end

local function compare_nonmember_sort_text(compare, entry1, entry2)
  if is_member_completion() then
    return nil
  end

  return compare.sort_text(entry1, entry2)
end

local function compare_alphabetically(entry1, entry2)
  local label1 = entry_label(entry1)
  local label2 = entry_label(entry2)
  local insensitive = vim.stricmp(label1, label2)

  if insensitive ~= 0 then
    return insensitive < 0
  elseif label1 ~= label2 then
    return label1 < label2
  end

  return nil
end

local function filter_lsp_entry(entry, context)
  if is_named_argument_value(context) and is_named_parameter(entry) then
    return false
  end

  local name = parameter_name(entry)
  if name and require('config.lsp.autocomplete.python_signature').is_parameter_consumed(name) then
    return false
  end

  if show_all_members or not is_member_completion(context) then
    return true
  end

  return not is_dunder(entry_label(entry))
end

local function setup_parameter_highlight()
  local function apply()
    vim.api.nvim_set_hl(0, 'CmpItemKindParameter', {
      default = true,
      link = 'DiagnosticHint',
    })
  end

  apply()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('python-completion-highlight', { clear = true }),
    callback = apply,
  })
end

local function complete_or_show_all(cmp, fallback)
  if cmp.visible() and is_member_completion() and not show_all_members then
    show_all_members = true
    vim.notify('Python completion: showing all members', vim.log.levels.INFO)
  end

  if not cmp.complete() then
    fallback()
  end
end

function M.setup(cmp)
  local compare = cmp.config.compare

  cmp.setup.filetype('python', {
    mapping = {
      ['<C-Space>'] = cmp.mapping(function(fallback)
        complete_or_show_all(cmp, fallback)
      end, { 'i' }),
    },
    formatting = {
      format = function(entry, item)
        if entry.source.name == 'nvim_lsp' and is_named_parameter(entry) then
          item.kind = 'Parameter'
          item.kind_hl_group = 'CmpItemKindParameter'
          item.menu = ''
        end

        return item
      end,
    },
    sorting = {
      comparators = {
        compare_named_parameters,
        compare_visibility,
        compare.exact,
        function(entry1, entry2)
          return compare_nonmember_sort_text(compare, entry1, entry2)
        end,
        compare_alphabetically,
        compare.order,
      },
    },
    sources = {
      {
        name = 'nvim_lsp',
        entry_filter = filter_lsp_entry,
      },
      { name = 'luasnip' },
      { name = 'path' },
    },
  })

  cmp.event:on('menu_closed', function()
    show_all_members = false
  end)

  require('config.lsp.autocomplete.python_signature').setup()
  setup_parameter_highlight()
end

return M
