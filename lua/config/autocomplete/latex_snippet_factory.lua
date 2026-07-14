local M = {}

local function has_option(options, option)
  return type(options) == 'string' and options:find(option, 1, true) ~= nil
end

local function marker_at(text, pos)
  local rest = text:sub(pos)
  local _, finish, index, default = rest:find '^%${(%d+):([^}]*)}'

  if finish then
    return finish, { kind = 'insert', index = tonumber(index), default = default }
  end

  _, finish, index = rest:find '^%$(%d+)'

  if finish then
    return finish, { kind = 'insert', index = tonumber(index), default = '' }
  end

  _, finish, index = rest:find '^%[%[(%d+)%]%]'

  if finish then
    return finish, { kind = 'capture', index = tonumber(index) }
  end

  _, finish = rest:find '^%${VISUAL}'

  if finish then
    return finish, { kind = 'visual' }
  end
end

local function make_insert_node(ls, seen_insert_nodes, obsidian_index, default)
  local jump_index = obsidian_index + 1

  if seen_insert_nodes[jump_index] then
    return require('luasnip.extras').rep(jump_index)
  end

  seen_insert_nodes[jump_index] = true
  return ls.insert_node(jump_index, default)
end

local function make_capture_node(ls, capture_index)
  return ls.function_node(function(_, snip)
    return snip.captures[capture_index + 1] or ''
  end)
end

local function split_text_node(text)
  if not text:find('\n', 1, true) then
    return text
  end

  text = text:gsub('\r\n', '\n')

  local lines = {}
  local start = 1

  while true do
    local newline = text:find('\n', start, true)

    if not newline then
      table.insert(lines, text:sub(start))
      break
    end

    table.insert(lines, text:sub(start, newline - 1))
    start = newline + 1
  end

  return lines
end

local function make_nodes(ls, replacement)
  if type(replacement) == 'function' then
    return {
      ls.function_node(function(_, snip)
        return replacement(snip.captures, snip)
      end),
    }
  end

  local nodes = {}
  local seen_insert_nodes = {}
  local visual_index = 1
  local pos = 1

  while pos <= #replacement do
    local finish, marker = marker_at(replacement, pos)

    if marker then
      if marker.kind == 'insert' then
        table.insert(nodes, make_insert_node(ls, seen_insert_nodes, marker.index, marker.default))
      elseif marker.kind == 'capture' then
        table.insert(nodes, make_capture_node(ls, marker.index))
      elseif marker.kind == 'visual' then
        table.insert(nodes, make_insert_node(ls, seen_insert_nodes, visual_index, ''))
        visual_index = visual_index + 1
      end

      pos = pos + finish
    else
      local next_pos = pos + 1

      while next_pos <= #replacement and not marker_at(replacement, next_pos) do
        next_pos = next_pos + 1
      end

      table.insert(nodes, ls.text_node(split_text_node(replacement:sub(pos, next_pos - 1))))
      pos = next_pos
    end
  end

  return nodes
end

local function make_condition(spec, conditions)
  if has_option(spec.options, 'm') or has_option(spec.options, 'M') then
    return conditions.in_mathzone
  end

  if has_option(spec.options, 't') then
    return conditions.in_textzone
  end
end

local function make_word_trigger(spec, is_regex)
  if spec.wordTrig ~= nil then
    return spec.wordTrig
  end

  return not is_regex
end

function M.from_specs(ls, specs, conditions)
  local snippets = {}

  for _, spec in ipairs(specs) do
    if not spec.disabled then
      local is_regex = spec.regTrig or has_option(spec.options, 'r')
      local trigger = {
        trig = spec.trigger,
        name = spec.name or spec.description,
        dscr = spec.description,
        trigEngine = is_regex and 'pattern' or 'plain',
        wordTrig = make_word_trigger(spec, is_regex),
        snippetType = has_option(spec.options, 'A') and 'autosnippet' or 'snippet',
      }

      if is_regex then
        trigger.regTrig = true
      end

      local opts = {
        condition = make_condition(spec, conditions),
        show_condition = make_condition(spec, conditions),
        priority = spec.priority,
      }

      table.insert(snippets, ls.snippet(trigger, make_nodes(ls, spec.replacement), opts))
    end
  end

  return snippets
end

return M
