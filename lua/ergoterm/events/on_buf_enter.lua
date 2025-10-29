---@diagnostic disable: invisible

local M = {}

---@param term Terminal
function M.on_buf_enter(term)
  term:_set_return_mode()
  term:_set_last_focused()
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.on_buf_enter(...)
  end
})
