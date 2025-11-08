---Collection methods for managing terminal instances

local M = {}

local select = require("ergoterm.collection.select")

---@class State
---@field last_focused Terminal? Last focused terminal
---@field last_focused_bang_target Terminal? Last focused terminal with `bang_target` setting
---@field ids number[] All used terminal IDs in this session, even when terminals are deleted
---@field terminals Terminal[] All terminals in this session, excluding those that have been deleted
---@field universal_selection boolean Whether to ignore `auto_list` setting in selection and command' bang behavior
M._state = {
  last_focused = nil,
  last_focused_bang_target = nil,
  ids = {},
  terminals = {},
  universal_selection = false
}

---Finds the first terminal matching the given condition
---
---@param predicate fun(term: Terminal): boolean function that returns true for matching terminals
---@return Terminal?
function M.find(predicate)
  return M.filter(predicate)[1]
end

---Returns the terminal that currently has window focus
---
---@return Terminal?
function M.get_focused()
  return M.find(function(term)
    return term:is_focused()
  end)
end

---Returns the terminal associated with the current buffer
---
---@return Terminal?
function M.identify()
  return M.find(function(term)
    return term._state.bufnr == vim.api.nvim_get_current_buf()
  end)
end

---Returns the most recently focused terminal
---
---If `universal_selection` is enabled, returns the last focused terminal regardless
---of its `bang_target` flag. Otherwise, returns the last focused terminal that is a bang target.
---
---@return Terminal?
function M.get_target_for_bang()
  if M._state.universal_selection then
    return M._state.last_focused
  else
    return M._state.last_focused_bang_target
  end
end

---Gets a terminal by its unique ID
---
---@param id number
---@return Terminal?
function M.get(id)
  return M._state.terminals[id]
end

---Finds the terminal with the specified name
---
---@param name string
---@return Terminal?
function M.get_by_name(name)
  return M.find(function(term)
    return term.name == name
  end)
end

---Returns all terminals matching the given condition
---
---@param predicate fun(term: Terminal): boolean function that returns true for matching terminals
---@return Terminal[] array of all matching terminals
function M.filter(predicate)
  return vim.tbl_filter(predicate, M._state.terminals)
end

---Returns all terminals in the current session
---
---@return Terminal[]
function M.get_all()
  return M.filter(function(_) return true end)
end

---Returns all terminals that have the specified tag
---
---@param tag string the tag to search for
---@return Terminal[]
function M.filter_by_tag(tag)
  return M.filter(function(term)
    return vim.tbl_contains(term.tags, tag)
  end)
end

---@class TerminalSelectDefaultsOptionalTerminals : TerminalSelectDefaults
---@field terminals? Terminal[] array of terminals to choose from.

---Presents a picker interface for terminal selection
---
---The available terminals default to:
---
---- If `universal_selection` is disabled (default): all terminals that are auto_list and
---  either active (started or stopped but still with active buffer) or sticky.
---- If `universal_selection` is enabled: all terminals.
---
---@param defaults? TerminalSelectDefaultsOptionalTerminals table containing terminals, prompt, callbacks and picker
---@return any result from the picker, or nil if no terminals available
function M.select(defaults)
  defaults = defaults or {}
  defaults.terminals = defaults.terminals or (M._state.universal_selection and M.get_all() or
    M._find_auto_list_terminals_for_picker())

  return select(defaults)
end

M.select_started = select.select_started

---@class CleanupOptions
---@field force? boolean whether to force removal of sticky terminals from the session (default: false)

---Cleans up all terminals in the current session
---
---This is a destructive operation that cannot be undone.
---
---@param opts? CleanupOptions options for cleanup
function M.cleanup_all(opts)
  opts = opts or {}
  local terminals = M.get_all()
  for _, term in ipairs(terminals) do
    term:cleanup(opts)
  end
end

---Accesses internal module state
---
---Primarily used for debugging and testing.
---
---@param key string
---@return any the state value for the given key
function M.get_state(key)
  return M._state[key]
end

---Toggles universal selection mode
---
---When universal selection is enabled, all terminals are shown in pickers and
---can be set as last focused, regardless of their auto_list flag. This provides
---a temporary override for the auto_list setting.
---
---@return boolean the new state of universal_selection after toggling
function M.toggle_universal_selection()
  M._state.universal_selection = not M._state.universal_selection
  return M._state.universal_selection
end

---Resets the terminal ID sequence back to 1
---
---Terminal IDs are normally never reused, even after deletion. This function
---clears the ID history, allowing the sequence to restart from 1. Useful for
---testing.
function M.reset_ids()
  M._state.ids = {}
end

---@private
function M._filter_defaults_for_picker()
  if M._state.universal_selection then
    return M.get_all()
  else
    return M.filter(function(term)
      return term.auto_list and (term:is_active() or term.sticky)
    end)
  end
end

---@private
function M._find_auto_list_terminals_for_picker()
  return M.filter(function(term)
    return term.auto_list and (term:is_active() or term.sticky)
  end)
end

---@private
function M._compute_id()
  return #M._state.ids + 1
end

---@private
function M._add_terminal_to_state(term)
  table.insert(M._state.ids, term.id)
  M._state.terminals[term.id] = term
end

return M
