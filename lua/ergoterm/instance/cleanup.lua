---@diagnostic disable: invisible

---@module "ergoterm.collection"
local collection = require("ergoterm.collection")

local M = {}

--- @param term Terminal
---@param opts? CleanupOptions options for cleanup
function M.cleanup(term, opts)
  opts = opts or {}
  local force = vim.F.if_nil(opts.force, false)

  if term:is_started() then term:stop() end
  if term:is_open() then term:close() end
  if term._state.bufnr then term._state.bufnr = nil end
  M._maybe_clear_last_focused(term)
  M._maybe_remove_from_collection_state(term, force)
  return term
end

---@param term Terminal
function M.is_cleaned_up(term)
  return term._state.has_been_started and term._state.bufnr == nil
end

function M._maybe_clear_last_focused(term)
  if collection._state.last_focused == term then
    collection._state.last_focused = nil
  end
  if collection._state.last_focused_bang_target == term then
    collection._state.last_focused_bang_target = nil
  end
end

function M._maybe_remove_from_collection_state(term, force)
  if not term.sticky or force then
    collection._state.terminals[term.id] = nil
  end
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.cleanup(...)
  end
})
