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
  local category1 = visibility_category(entry1)
  local category2 = visibility_category(entry2)
  if category1 ~= category2 then
    return category1 < category2
  end

  return nil
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
  if show_all_members or not is_member_completion(context) then
    return true
  end

  return not is_dunder(entry_label(entry))
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
    sorting = {
      comparators = {
        compare_visibility,
        compare.exact,
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
end

return M
