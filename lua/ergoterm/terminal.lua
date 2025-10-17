---@deprecated Use require('ergoterm') instead
---
---This module is maintained for backward compatibility only.
---All functionality has been moved to:
--- - ergoterm.collection (internal) for collection methods
--- - ergoterm.instance (internal) for Terminal class
--- - ergoterm (public API) as the main entry point

local utils = require("ergoterm.utils")

local warned = false
if not warned then
  utils.notify(
    "require('ergoterm.terminal') is deprecated. Use require('ergoterm') instead.",
    "warn"
  )
  warned = true
end

local collection = require("ergoterm.collection")
local instance = require("ergoterm.instance")

local M = {}

M.find = collection.find
M.get_focused = collection.get_focused
M.identify = collection.identify
M.get_last_focused = collection.get_last_focused
M.get = collection.get
M.get_by_name = collection.get_by_name
M.filter = collection.filter
M.get_all = collection.get_all
M.filter_by_tag = collection.filter_by_tag
M.select = collection.select
M.select_started = collection.select_started
M.cleanup_all = collection.cleanup_all
M.get_state = collection.get_state
M.toggle_universal_selection = collection.toggle_universal_selection
M.reset_ids = collection.reset_ids

M.Terminal = instance.Terminal

function M.with_defaults(custom_defaults)
  return {
    new = function(_, args)
      args = args or {}
      local merged_args = vim.tbl_deep_extend("force", custom_defaults, args)
      return instance.Terminal:new(merged_args)
    end
  }
end

return M
