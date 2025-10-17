---@module "ergoterm.lazy"
local lazy = require("ergoterm.lazy")

---@module "ergoterm.config"
local config = lazy.require("ergoterm.config")
---@module "ergoterm.utils"
local utils = lazy.require("ergoterm.utils")

local M = {}

---@class TerminalSelectDefaults
---@field prompt? string text to display in the picker
---@field callbacks? table<string, PickerCallbackDefinition>|fun(term: Terminal)
---@field picker? Picker

---@class TerminalSelectDefaultsRequiredTerminals : TerminalSelectDefaults
---@field terminals Terminal[] array of terminals to choose from.

---Presents a picker interface for terminal selection
---
---Terminals default to those that are started or sticky (unless selectable is false),
---unless universal_selection is enabled, in which case all terminals are shown.
---
---@param defaults TerminalSelectDefaultsRequiredTerminals table containing terminals, prompt, callbacks and picker
---@return any result from the picker, or nil if no terminals available
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

---@private
function M._parse_callbacks(callbacks)
  if type(callbacks) == "function" then
    return { default = { fn = callbacks, desc = "Default action" } }
  elseif callbacks then
    return callbacks
  else
    return M._get_default_callbacks()
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
