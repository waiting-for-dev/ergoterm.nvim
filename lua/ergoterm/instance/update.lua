---@diagnostic disable: invisible

---@module "ergoterm.mode"
local mode = require("ergoterm.mode")
---@module "ergoterm.utils"
local utils = require("ergoterm.utils")

local ALLOWED_SETTINGS = {
  "auto_scroll",
  "bang_target",
  "watch_files",
  "clear_env",
  "cleanup_on_success",
  "cleanup_on_failure",
  "default_action",
  "layout",
  "env",
  "name",
  "meta",
  "float_props",
  "float_winblend",
  "persist_mode",
  "auto_list",
  "size",
  "start_in_insert",
  "sticky",
  "on_close",
  "on_create",
  "on_focus",
  "on_job_stderr",
  "on_job_stdout",
  "on_job_exit",
  "on_open",
  "on_start",
  "on_stop",
  "show_on_success",
  "show_on_failure",
  "tags"
}

local M = {}

---@class UpdateOptions
---@field deep_merge? boolean whether to deep merge table properties (default: false)
---
---@param term Terminal
---@param settings TerminalCreateSettings
---@param opts? UpdateOptions
---
---@return Terminal?
function M.update(term, settings, opts)
  opts = opts or {}
  local deep_merge = opts.deep_merge or false

  for setting, _ in pairs(settings) do
    if not vim.tbl_contains(ALLOWED_SETTINGS, setting) then
      return utils.notify(
        string.format("Cannot change %s after terminal creation", setting),
        "error"
      )
    end
  end

  for k, v in pairs(settings) do
    M._update_setting(term, k, v, deep_merge)
  end
  M._recompute_state(term)

  return term
end

---@private
---@param term Terminal
---@param setting string
---@param value any
---@param deep_merge boolean
function M._update_setting(term, setting, value, deep_merge)
  local should_merge = deep_merge
    and type(value) == "table"
    and type(term[setting]) == "table"
    and not vim.islist(value)

  if should_merge then
    term[setting] = vim.tbl_deep_extend("force", term[setting], value)
  else
    term[setting] = value
  end
end

---@private
---@param term Terminal
function M._recompute_state(term)
  term._state.mode = mode.get_initial(term.start_in_insert)
  term._state.layout = term.layout
  term._state.on_job_exit = term:_compute_exit_handler(term.on_job_exit)
  term._state.on_job_stdout = term:_compute_output_handler(term.on_job_stdout)
  term._state.on_job_stderr = term:_compute_output_handler(term.on_job_stderr)
  term._state.size = term:_compute_size()
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.update(...)
  end
})
