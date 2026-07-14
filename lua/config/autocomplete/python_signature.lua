local M = {}

local method = 'textDocument/signatureHelp'
local compact_namespace = vim.api.nvim_create_namespace 'python-signature-compact'
local expanded_namespace = vim.api.nvim_create_namespace 'python-signature-expanded'
local states = {}

local function state_for(bufnr)
  states[bufnr] = states[bufnr] or { generation = 0 }
  return states[bufnr]
end

local function close_expanded(state)
  if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
    vim.api.nvim_win_close(state.float_win, true)
  end

  state.float_buf = nil
  state.float_win = nil
  state.expanded = false
end

local function clear(bufnr)
  local state = states[bufnr]
  if not state then
    return
  end

  state.generation = state.generation + 1
  close_expanded(state)

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, compact_namespace, 0, -1)
  end

  states[bufnr] = nil
end

local function active_parameter(state, index)
  local signature = state.signatures[index]
  return signature.activeParameter or state.active_parameter or 0
end

local function parameter_label(signature, index)
  local parameter = signature.parameters and signature.parameters[index + 1]
  if not parameter then
    return nil
  end

  if type(parameter.label) == 'string' then
    return parameter.label
  end

  if type(parameter.label) == 'table' then
    return signature.label:sub(parameter.label[1] + 1, parameter.label[2])
  end

  return nil
end

local function text_before_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
  lines[#lines] = (lines[#lines] or ''):sub(1, col)
  return table.concat(lines, '\n')
end

local function scan_delimiters(text, on_comma)
  local stack = {}
  local quote
  local triple = false
  local comment = false
  local index = 1

  while index <= #text do
    local char = text:sub(index, index)

    if comment then
      if char == '\n' then
        comment = false
      end
      index = index + 1
    elseif quote then
      if char == '\\' then
        index = index + 2
      elseif triple and text:sub(index, index + 2) == quote:rep(3) then
        quote = nil
        triple = false
        index = index + 3
      elseif not triple and char == quote then
        quote = nil
        index = index + 1
      else
        index = index + 1
      end
    elseif char == '#' then
      comment = true
      index = index + 1
    elseif char == "'" or char == '"' then
      quote = char
      triple = text:sub(index, index + 2) == char:rep(3)
      index = index + (triple and 3 or 1)
    elseif char == '(' or char == '[' or char == '{' then
      table.insert(stack, { char = char, position = index })
      index = index + 1
    elseif char == ')' or char == ']' or char == '}' then
      table.remove(stack)
      index = index + 1
    elseif char == ',' and on_comma then
      on_comma(index, #stack)
      index = index + 1
    else
      index = index + 1
    end
  end

  return stack
end

local function current_call_arguments()
  local text = text_before_cursor()
  local stack = scan_delimiters(text)
  local opening = stack[#stack]
  if not opening or opening.char ~= '(' then
    return nil
  end

  local arguments_text = text:sub(opening.position + 1)
  local arguments = {}
  local start = 1
  scan_delimiters(arguments_text, function(position, depth)
    if depth == 0 then
      table.insert(arguments, arguments_text:sub(start, position - 1))
      start = position + 1
    end
  end)
  table.insert(arguments, arguments_text:sub(start))
  return arguments, opening.position
end

local function argument_context_key()
  local arguments, opening_position = current_call_arguments()
  if not arguments then
    return nil
  end

  local current = vim.trim(arguments[#arguments])
  local named = current:match '^([%a_][%w_]*)%s*=' or ''
  return ('%d:%d:%s'):format(opening_position, #arguments, named)
end

local function fallback_position(client)
  local text = text_before_cursor()
  local stack = scan_delimiters(text)
  local opening = stack[#stack]
  if not opening or opening.char ~= '(' then
    return nil
  end

  local arguments_text = text:sub(opening.position + 1)
  local segment_start = 1
  scan_delimiters(arguments_text, function(position, depth)
    if depth == 0 then
      segment_start = position + 1
    end
  end)

  local segment = arguments_text:sub(segment_start)
  local named_prefix = segment:match '^%s*[%a_][%w_]*%s*=%s*'
  local leading_space = segment:match '^%s*' or ''
  local offset = named_prefix and #named_prefix or #leading_space
  local byte_count = opening.position + segment_start - 1 + offset
  local prefix = text:sub(1, byte_count)
  local line = select(2, prefix:gsub('\n', ''))
  local current_line = prefix:match '([^\n]*)$' or ''

  return {
    textDocument = vim.lsp.util.make_text_document_params(0),
    position = {
      line = line,
      character = vim.str_utfindex(current_line, client.offset_encoding, #current_line, false),
    },
  }
end

local function parameter_descriptors(signature)
  local descriptors = {}
  local search_start = 1
  local keyword_only = false

  for index = 0, #(signature.parameters or {}) - 1 do
    local label = parameter_label(signature, index)
    if label then
      local label_start, label_end = signature.label:find(label, search_start, true)
      local gap = label_start and signature.label:sub(search_start, label_start - 1) or ''
      if gap:match '/%s*,' then
        for _, descriptor in ipairs(descriptors) do
          if descriptor.kind == 'positional' then
            descriptor.kind = 'positional_only'
          end
        end
      end
      if gap:match '%*%s*,' then
        keyword_only = true
      end

      local stars, name = label:match '^%s*(%**)%s*([%a_][%w_]*)'
      local kind = keyword_only and 'keyword_only' or 'positional'
      if stars == '*' then
        kind = 'var_positional'
        keyword_only = true
      elseif stars == '**' then
        kind = 'var_keyword'
      end

      if name then
        table.insert(descriptors, { name = name, kind = kind })
      end
      search_start = label_end and label_end + 1 or search_start
    end
  end

  if signature.label:sub(search_start):match '/%s*[,)]' then
    for _, descriptor in ipairs(descriptors) do
      if descriptor.kind == 'positional' then
        descriptor.kind = 'positional_only'
      end
    end
  end

  return descriptors
end

local function consumed_parameters(state)
  local arguments = current_call_arguments()
  if not arguments then
    return {}
  end

  local consumed = {}
  local positional_count = 0
  for index = 1, #arguments - 1 do
    local argument = vim.trim(arguments[index])
    local named = argument:match '^([%a_][%w_]*)%s*='
    if argument:match '^[%a_][%w_]*%s*==' then
      named = nil
    end
    if named then
      consumed[named] = true
    elseif argument ~= '' and argument:sub(1, 1) ~= '*' then
      positional_count = positional_count + 1
    end
  end

  for _, parameter in ipairs(parameter_descriptors(state.signatures[state.index])) do
    if positional_count > 0 then
      if parameter.kind == 'positional' or parameter.kind == 'positional_only' then
        consumed[parameter.name] = true
        positional_count = positional_count - 1
      elseif parameter.kind == 'var_positional' then
        positional_count = 0
      end
    end
  end

  return consumed
end

function M.is_parameter_consumed(name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local state = states[bufnr]
  if not (state and state.signatures and state.signatures[state.index]) or vim.api.nvim_get_current_buf() ~= bufnr then
    return false
  end

  return consumed_parameters(state)[name] == true
end

local function shorten(text, limit)
  if vim.fn.strchars(text) <= limit then
    return text
  end

  return vim.fn.strcharpart(text, 0, limit - 1) .. '…'
end

local function render_compact(bufnr)
  local state = states[bufnr]
  if not state or not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end

  local signature = state.signatures[state.index]
  local parameter = parameter_label(signature, active_parameter(state, state.index))
  local hint
  if parameter then
    hint = shorten(parameter, 60)
  else
    local consumed = consumed_parameters(state)
    local available = {}
    local accepts_arbitrary_names = false
    for _, descriptor in ipairs(parameter_descriptors(signature)) do
      if descriptor.kind == 'var_keyword' then
        accepts_arbitrary_names = true
      elseif descriptor.kind ~= 'positional_only' and descriptor.kind ~= 'var_positional' and not consumed[descriptor.name] then
        table.insert(available, descriptor.name .. '=')
      end
    end

    if available[1] then
      hint = shorten('named parameters: ' .. table.concat(available, ', '), 60)
    elseif accepts_arbitrary_names then
      hint = 'additional named parameters accepted'
    elseif signature.parameters and signature.parameters[1] then
      hint = 'all parameters supplied'
    else
      hint = 'no parameters'
    end
  end
  local overload = #state.signatures > 1 and ('  [%d/%d]'):format(state.index, #state.signatures) or ''
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1

  vim.api.nvim_buf_clear_namespace(bufnr, compact_namespace, 0, -1)
  vim.api.nvim_buf_set_extmark(bufnr, compact_namespace, row, 0, {
    virt_text = {
      { '  ← ', 'Comment' },
      { hint, 'LspSignatureActiveParameter' },
      { overload, 'Comment' },
    },
    virt_text_pos = 'eol',
    priority = 90,
  })
end

local function render_expanded(bufnr)
  local state = states[bufnr]
  if not state or vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end

  close_expanded(state)
  state.expanded = true

  local signature = vim.deepcopy(state.signatures[state.index])
  local parameter = active_parameter(state, state.index)
  signature.activeParameter = parameter

  local lines, highlight = vim.lsp.util.convert_signature_help_to_markdown_lines({
    signatures = { signature },
    activeSignature = 0,
    activeParameter = parameter,
  }, 'python')

  if not lines or vim.tbl_isempty(lines) then
    state.expanded = false
    return
  end

  local title = #state.signatures > 1 and ('Signature %d/%d · <C-s> next signature'):format(state.index, #state.signatures) or 'Signature · <C-s> close'

  state.float_buf, state.float_win = vim.lsp.util.open_floating_preview(lines, 'markdown', {
    anchor_bias = 'above',
    border = 'rounded',
    focusable = false,
    max_height = 8,
    max_width = math.min(80, math.max(40, vim.o.columns - 10)),
    title = title,
    title_pos = 'center',
  })

  if highlight then
    vim.api.nvim_buf_clear_namespace(state.float_buf, expanded_namespace, 0, -1)
    vim.hl.range(state.float_buf, expanded_namespace, 'LspSignatureActiveParameter', { highlight[1], highlight[2] }, { highlight[3], highlight[4] })
  end
end

local function accept_result(bufnr, generation, result, expand)
  local state = states[bufnr]
  if not state or state.generation ~= generation then
    return
  end

  if not (result and result.signatures and result.signatures[1]) then
    clear(bufnr)
    return
  end

  state.signatures = result.signatures
  state.active_parameter = result.activeParameter
  state.index = math.min((result.activeSignature or 0) + 1, #result.signatures)
  state.context_key = argument_context_key()
  render_compact(bufnr)

  if expand then
    render_expanded(bufnr)
  end
end

local function request(bufnr, expand, retry_at_argument_start)
  if vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end

  local clients = vim.lsp.get_clients { bufnr = bufnr, method = method }
  local client = clients[1]
  if not client then
    clear(bufnr)
    return
  end

  local state = state_for(bufnr)
  state.generation = state.generation + 1
  state.context_key = argument_context_key()
  local generation = state.generation
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  local function send(request_params, can_retry)
    client:request(method, request_params, function(error, result)
      if error then
        clear(bufnr)
        return
      end

      if can_retry and not (result and result.signatures and result.signatures[1]) then
        local fallback = fallback_position(client)
        if fallback and not vim.deep_equal(fallback.position, request_params.position) then
          send(fallback, false)
          return
        end
      end

      accept_result(bufnr, generation, result, expand)
    end, bufnr)
  end

  send(params, retry_at_argument_start)
end

function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = states[bufnr]

  if not (state and state.signatures and state.signatures[1]) then
    request(bufnr, true, true)
    return
  end

  local expanded_is_open = state.float_win and vim.api.nvim_win_is_valid(state.float_win)
  if not expanded_is_open then
    render_expanded(bufnr)
  elseif #state.signatures > 1 then
    state.index = state.index % #state.signatures + 1
    render_compact(bufnr)
    render_expanded(bufnr)
  else
    close_expanded(state)
  end
end

local function configure_buffer(bufnr)
  vim.keymap.set('i', '<C-s>', M.toggle, {
    buffer = bufnr,
    desc = 'Show or cycle Python signature',
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup('python-signature-help', { clear = true })

  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'python',
    callback = function(args)
      configure_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].filetype == 'python' then
        configure_buffer(args.buf)

        if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
          vim.schedule(function()
            request(args.buf, false, true)
          end)
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd('InsertEnter', {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].filetype ~= 'python' then
        return
      end

      vim.schedule(function()
        if vim.api.nvim_get_current_buf() == args.buf and vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
          request(args.buf, false, true)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd('InsertCharPre', {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].filetype ~= 'python' or not vim.tbl_contains({ '(', ',', ')', '=' }, vim.v.char) then
        return
      end

      vim.schedule(function()
        if vim.api.nvim_get_current_buf() == args.buf and vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
          request(args.buf, false)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ 'TextChangedI', 'CursorMovedI' }, {
    group = group,
    callback = function(args)
      local state = states[args.buf]
      local context_key = argument_context_key()
      if vim.bo[args.buf].filetype == 'python' and state and context_key ~= state.context_key then
        state.context_key = context_key
        request(args.buf, false)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave', 'LspDetach' }, {
    group = group,
    callback = function(args)
      clear(args.buf)
    end,
  })

  if vim.bo.filetype == 'python' then
    local bufnr = vim.api.nvim_get_current_buf()
    configure_buffer(bufnr)

    if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
      vim.schedule(function()
        request(bufnr, false, true)
      end)
    end
  end
end

return M
