---@diagnostic disable: invisible

---@module "ergoterm.mode"
local mode = require("ergoterm.mode")

local M = {}

---@param term Terminal
function M.on_win_leave(term)
  if term.persist_mode then M._persist_mode(term) end
  if term._state.layout == "float" then term:close() end
  term:on_unfocus()
end

---@private
function M._persist_mode(term)
  term._state.mode = mode.get()
  return term
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.on_win_leave(...)
  end
})
