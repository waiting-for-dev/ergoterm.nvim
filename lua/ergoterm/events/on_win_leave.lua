---@diagnostic disable: invisible

local M = {}

---@param term Terminal
function M.on_win_leave(term)
  if term.persist_mode then term:_persist_mode() end
  if term._state.layout == "float" then term:close() end
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.on_win_leave(...)
  end
})
