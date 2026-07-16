local M = {}

local math_filetypes = {
  tex = true,
  latex = true,
  plaintex = true,
  markdown = true,
  rmd = true,
  quarto = true,
}

local math_envs = {
  equation = true,
  ['equation*'] = true,
  align = true,
  ['align*'] = true,
  aligned = true,
  gather = true,
  ['gather*'] = true,
  multline = true,
  ['multline*'] = true,
  split = true,
  cases = true,
}

local function is_escaped(text, index)
  local backslashes = 0
  index = index - 1

  while index >= 1 and text:sub(index, index) == '\\' do
    backslashes = backslashes + 1
    index = index - 1
  end

  return backslashes % 2 == 1
end

local function count_unescaped_token(text, token)
  local count = 0
  local index = 1

  while index <= #text do
    if text:sub(index, index + #token - 1) == token and not is_escaped(text, index) then
      count = count + 1
      index = index + #token
    else
      index = index + 1
    end
  end

  return count
end

local function count_inline_dollars(text)
  local count = 0
  local index = 1

  while index <= #text do
    if text:sub(index, index) == '$' and not is_escaped(text, index) then
      if text:sub(index, index + 1) == '$$' then
        index = index + 2
      else
        count = count + 1
        index = index + 1
      end
    else
      index = index + 1
    end
  end

  return count
end

local function lines_to_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)

  if #lines > 0 then
    lines[#lines] = lines[#lines]:sub(1, col)
  end

  return lines, row, math.max(col, 1)
end

local function in_math_syntax(row, col)
  for _, syntax_id in ipairs(vim.fn.synstack(row, col)) do
    local name = vim.fn.synIDattr(syntax_id, 'name'):lower()

    if name:find 'math' and (name:find 'tex' or name:find 'latex' or name:find 'markdown') then
      return true
    end
  end

  return false
end

local function in_text_mathzone(lines)
  local display_math = false
  local env_depth = 0

  for _, line in ipairs(lines) do
    if count_unescaped_token(line, '$$') % 2 == 1 then
      display_math = not display_math
    end

    for env in line:gmatch [[\begin%s*{([%w*]+)}]] do
      if math_envs[env] then
        env_depth = env_depth + 1
      end
    end

    for env in line:gmatch [[\end%s*{([%w*]+)}]] do
      if math_envs[env] then
        env_depth = math.max(env_depth - 1, 0)
      end
    end
  end

  return display_math or env_depth > 0 or count_inline_dollars(lines[#lines] or '') % 2 == 1
end

local function in_mathzone()
  if not math_filetypes[vim.bo.filetype] then
    return false
  end

  if vim.fn.exists '*vimtex#syntax#in_mathzone' == 1 then
    local ok, in_vimtex_math = pcall(vim.fn['vimtex#syntax#in_mathzone'])

    if ok and in_vimtex_math == 1 then
      return true
    end
  end

  local lines, row, col = lines_to_cursor()
  return in_math_syntax(row, col) or in_text_mathzone(lines)
end

local function in_textzone()
  return not in_mathzone()
end

function M.setup()
  local ls = require 'luasnip'
  local factory = require 'config.lsp.autocomplete.latex_snippet_factory'
  local config = require 'config.lsp.autocomplete.latex_snippets'
  for _, filetype in ipairs(config.filetypes) do
    ls.add_snippets(
      filetype,
      factory.from_specs(ls, config.snippets, {
        in_mathzone = in_mathzone,
        in_textzone = in_textzone,
      })
    )
  end
end

return M
