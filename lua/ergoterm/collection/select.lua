---@module "ergoterm.config"
local config = require("ergoterm.config")
---@module "ergoterm.utils"
local utils = require("ergoterm.utils")

local M = {}

---@class TerminalSelectDefaults
---@field prompt? string text to display in the picker
---@field callbacks? table<string, PickerCallbackDefinition>|fun(term: Terminal)
---@field picker? Picker

---@class TerminalSelectDefaultsRequiredTerminals : TerminalSelectDefaults
---@field terminals Terminal[] array of terminals to choose from.

---@param defaults TerminalSelectDefaultsRequiredTerminals table containing terminals, prompt, callbacks and picker
---@return any result from the picker, or nil if no terminals available
---@private
function M.select(defaults)
  local terminals = defaults.terminals
  local prompt = defaults.prompt or "Please select a terminal"
  local picker = defaults.picker or config.build_picker(config)
  local callbacks = M._parse_callbacks(defaults.callbacks)
  if #terminals == 0 then
    return utils.notify("No ergoterm terminals available", "info")
  elseif M._can_short_circuit(terminals, callbacks) then
    return callbacks.default.fn(terminals[1])
  else
    return picker.select(terminals, prompt, callbacks)
  end
end

---@class TerminalSelectStartedDefaults : TerminalSelectDefaultsRequiredTerminals
---@field default? Terminal terminal to select when none of the provided terminals are started

---Presents a picker interface for started terminals only
---
---Filters the provided terminals to only include those that have been started,
---then presents them in a picker interface. All other behavior matches `select()`.
---If none of the terminals are started and a default terminal is provided,
---that terminal is selected instead.
---
---@param defaults TerminalSelectStartedDefaults
---@return any result from the picker, or nil if no started terminals available
---@private
function M.select_started(defaults)
  defaults = defaults or {}
  local terminals = M._filter_started_terminals_or_default_if_none(defaults.terminals, defaults.default)
  return M.select({
    terminals = terminals,
    prompt = defaults.prompt,
    callbacks = defaults.callbacks,
    picker = defaults.picker
  })
end

---@private
function M._filter_started_terminals_or_default_if_none(terminals, default)
  local started_terminals = vim.tbl_filter(function(term)
    return term:is_started()
  end, terminals)
  if #started_terminals == 0 and default then
    return { default }
  else
    return started_terminals
  end
end

---@private
function M._parse_callbacks(callbacks)
  if type(callbacks) == "function" then
    return { default = { fn = callbacks, desc = "Default action" } }
  elseif callbacks then
    return callbacks
  else
    return config.get_all_picker_select_callbacks()
  end
end

---@private
function M._can_short_circuit(terminals, callbacks)
  return #terminals == 1 and vim.tbl_count(callbacks) == 1 and callbacks.default
end

---@private
function M._get_default_callbacks()
  local select_actions = config.get("picker.select_actions")
  local extra_select_actions = config.get("picker.extra_select_actions")
  return vim.tbl_extend("force", select_actions, extra_select_actions)
end

return setmetatable(M, {
  __call = function(_, defaults)
    return M.select(defaults)
  end
})
