---@diagnostic disable: invisible

---@module "ergoterm.collection"
local collection = require("ergoterm.collection")
---@module "ergoterm.mode"
local mode = require("ergoterm.mode")

local M = {}

---@param term Terminal
function M.on_buf_enter(term)
  M._set_last_focused(term)
  M._set_return_mode(term)
  term:on_focus()
end

---@private
---@param term Terminal
function M._set_last_focused(term)
  collection._state.last_focused = term
  if term.bang_target then
    collection._state.last_focused_bang_target = term
  end
  return term
end

---@private
---@param term Terminal
function M._set_return_mode(term)
  if term.persist_mode then
    M._restore_mode(term)
  else
    M._set_initial_mode(term)
  end
end

---@private
---@param term Terminal
function M._restore_mode(term)
  mode.set(term._state.mode)
  return term
end

---@private
---@param term Terminal
function M._set_initial_mode(term)
  mode.set_initial(term.start_in_insert)
  return term
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.on_buf_enter(...)
  end
})
