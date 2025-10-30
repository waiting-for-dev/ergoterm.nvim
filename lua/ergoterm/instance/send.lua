---@diagnostic disable: invisible

---@module "ergoterm.lazy"
local lazy = require("ergoterm.lazy")

---@module "ergoterm.config"
local config = lazy.require("ergoterm.config")
---@module "ergoterm.instance.send.text_decorators"
local text_decorators = lazy.require("ergoterm.instance.send.text_decorators")
---@module "ergoterm.instance.send.text_selector"
local text_selector = lazy.require("ergoterm.instance.send.text_selector")
---@module "ergoterm.utils"
local utils = lazy.require("ergoterm.utils")

local M = {}

---@alias send_last "last"
---@alias send_input_type selection_type | send_last
---@alias send_action "focus" | "open" | "start"

---@class SendOptions
---@field action? send_action terminal interaction mode (default: "focus")
---@field trim? boolean remove leading/trailing whitespace (default: true)
---@field new_line? boolean append newline for command execution (default: true)
---@field decorator? string | fun(text: string[]): string[] transform text before sending

---@param term Terminal
---@param input send_input_type | string[]
---@param opts? SendOptions
---@return Terminal
function M.send(term, input, opts)
  opts = opts or {}
  local action = opts.action or "focus"
  local trim = opts.trim == nil or opts.trim
  local new_line = opts.new_line == nil or opts.new_line
  local decorator = M._parse_decorator(opts.decorator)
  if not M._validate_selection_type(input) then return term end
  local computed_input = M._parse_input(input, term)
  term._state.last_sent = vim.deepcopy(computed_input)
  computed_input = M._maybe_add_new_line(computed_input, new_line)
  computed_input = M._maybe_trim_input(computed_input, trim)
  computed_input = decorator(computed_input)
  M._perform_action(term, action)
  vim.fn.chansend(term._state.job_id, computed_input)
  term:_scroll_bottom()
  return term
end

---@param term Terminal
---@param action? send_action terminal interaction mode (default: "focus")
function M.clear(term, action)
  local clear = utils.is_windows() and "cls" or "clear"
  return M.send(term, { clear }, { action = action })
end

function M._validate_selection_type(input)
  local valid_selection_types = { "single_line", "visual_lines", "visual_selection", "last" }
  if type(input) == "string" and not vim.tbl_contains(valid_selection_types, input) then
    utils.notify(
      string.format("Invalid input type '%s'. Must be a table with one item per line or one of: %s", input,
        table.concat(valid_selection_types, ", ")),
      "error"
    )
    return false
  end
  return true
end

function M._parse_decorator(decorator)
  if type(decorator) == "string" then
    local all_decorators = config.get_text_decorators()
    return all_decorators[decorator] or utils.notify(
      string.format("Decorator '%s' not found. Using identity decorator.", decorator),
      "warn"
    ) and text_decorators.identity
  else
    return decorator or text_decorators.identity
  end
end

function M._parse_input(input, term)
  if input == "last" then
    return vim.deepcopy(term._state.last_sent)
  elseif type(input) == "string" then
    return text_selector.select(input)
  else
    return input
  end
end

function M._maybe_add_new_line(input, new_line)
  if new_line then
    table.insert(input, "")
  end
  return input
end

function M._maybe_trim_input(input, trim)
  if trim then
    return vim.tbl_map(function(line)
      return line:gsub("^%s+", ""):gsub("%s+$", "")
    end, input)
  end
  return input
end

function M._perform_action(term, action)
  if action == "start" then
    term:start()
  elseif action == "open" then
    term:open()
  elseif action == "focus" then
    term:focus()
  end
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.send(...)
  end
})
